# Component boilerplate

Not a module. Every component under `modules/` starts with these three files,
copied verbatim; only `resource_set` in `_context.tf` changes (the module's
directory name). Do not add `variables` beyond these two.

The cloud's backend and provider are not in the component: they come from
[`modules/_cloud/<cloud>/`](../_cloud) when the module is staged for the
unit's cloud (`scripts/stage-module <module> <cloud> <out>`), together with
the component's own `cloud/<cloud>/*.tf` slice, if it has one. Files at the
module root must not name an `aws_*` or `azurerm_*` address.

## `_context.tf`

```hcl
variable "config_file" {
  description = "Path to this unit's YAML (environments/<tier>/<env_id>/<region>/<cluster>/<component>[.<instance>].yaml)."
  type        = string
}

variable "pipeline_user" {
  description = "Who ran the pipeline (GITHUB_ACTOR)."
  type        = string
  default     = "unknown"
}

module "context" {
  source = "git::https://github.com/Haykhay/phoenix-aws.git//infrastructure/modules/context?ref=v1.1.0"

  config_file   = var.config_file
  resource_set  = "COMPONENT"
  pipeline_user = var.pipeline_user
}

module "cluster" {
  source = "../cluster"

  cloud    = module.context.cloud
  state    = module.context.state
  env_id   = module.context.env_id
  region   = module.context.region
  cluster  = module.context.config.cluster
  dns_zone = try(module.context.config.dns_zone, "zone-1")
}

locals {
  environment  = module.context.env_id
  region       = module.context.region
  account_id   = module.context.account_id
  organisation = module.context.organisation
  cluster_key  = tostring(module.context.config.cluster)
  # <component>.<instance>.yaml -> instance; singletons have none.
  instance     = try(regex("^[^.]+\\.(.+)\\.yaml$", basename(var.config_file))[0], null)
  # Cluster- and instance-unique: research-sandbox-jdoe-euw1-1[-llama-3-8b]
  name_prefix  = join("-", compact([module.context.name_prefix, local.cluster_key, local.instance]))
  cluster_name = module.cluster.cluster_name
}
```

## `providers.tf`

```hcl
# A fresh cluster token per call (module.cluster.exec: aws eks get-token, or
# kubelogin on Azure): a token fetched once per run expires after 15 minutes,
# and Helm waits can be longer (vLLM: 30). The runner needs the aws CLI or
# kubelogin. The cloud's own provider comes from modules/_cloud/<cloud>.
provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = module.cluster.exec.command
      args        = module.cluster.exec.args
    }
  }
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = module.cluster.exec.command
    args        = module.cluster.exec.args
  }
}
```

## `versions.tf`

The cloud provider (`aws`, `azurerm`) is added to this block by `stage-module`, from `_cloud/<cloud>/required_providers.hcl`: Terraform allows one `required_providers` block per module.

```hcl
terraform {
  required_version = ">= 1.15.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

## Tests

One folder per cloud: `tests/aws/<component>.tftest.hcl` (and `tests/azure/`
once the component has an Azure slice); fixtures stay in `tests/fixtures/`.
They mock the cloud provider, helm and kubernetes, and override
`module.cluster.data.terraform_remote_state.core_platform[0]` / `.dns[0]` (AWS)
or `.core_platform_azure[0]` / `.dns_azure[0]` (Azure). Every module has at
least `plans_with_defaults` and `disabled_plans_nothing`.

```bash
scripts/test-module modules/<component>          # every cloud it has tests for
scripts/test-module modules/<component> aws      # one cloud
scripts/test-all                                 # every module
```
