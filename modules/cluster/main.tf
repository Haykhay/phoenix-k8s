# Which cluster a phoenix-k8s unit runs against, read from infrastructure's
# state: core-platform (regional) for the cluster, dns (global) for its zone.
# One pair per cloud: S3 on AWS, the environment's container on Azure. All
# reads default to empty so a missing state fails the plan on the validation
# below rather than inside a provider.
locals {
  aws   = var.cloud == "aws"
  azure = var.cloud == "azure"

  # Azure blob backend settings for a state key (module.context.state).
  azure_backend = local.azure ? {
    subscription_id      = var.state.subscription_id
    resource_group_name  = var.state.resource_group
    storage_account_name = var.state.storage_account
    container_name       = var.state.container
    use_oidc             = true
    use_azuread_auth     = true
  } : null
}

data "terraform_remote_state" "core_platform" {
  count   = local.aws ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.state.bucket
    region = var.state.region
    key    = "${var.env_id}/${var.region}/core-platform/terraform.tfstate"
  }
  defaults = {}
}

data "terraform_remote_state" "dns" {
  count   = local.aws ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.state.bucket
    region = var.state.region
    key    = "${var.env_id}/global/dns/terraform.tfstate"
  }
  defaults = {}
}

data "terraform_remote_state" "core_platform_azure" {
  count    = local.azure ? 1 : 0
  backend  = "azurerm"
  config   = merge(local.azure_backend, { key = "${var.env_id}/${var.region}/core-platform/terraform.tfstate" })
  defaults = {}
}

data "terraform_remote_state" "dns_azure" {
  count    = local.azure ? 1 : 0
  backend  = "azurerm"
  config   = merge(local.azure_backend, { key = "${var.env_id}/global/dns/terraform.tfstate" })
  defaults = {}
}

locals {
  core_platform = try(local.azure ? data.terraform_remote_state.core_platform_azure[0].outputs : data.terraform_remote_state.core_platform[0].outputs, {})
  dns_outputs   = try(local.azure ? data.terraform_remote_state.dns_azure[0].outputs : data.terraform_remote_state.dns[0].outputs, {})

  found   = can(local.core_platform.clusters[var.cluster])
  cluster = local.found ? local.core_platform.clusters[var.cluster] : null
  dns     = try(local.dns_outputs.zones[var.dns_zone], null)

  # Placeholder keeps the providers from seeing null
  # while the validation below fails the plan.
  cluster_name = local.found ? local.cluster.cluster_name : "cluster-missing"

  # How the helm/kubernetes providers get a token, per call: the job's own
  # credentials either way (Terraform-Role / Terraform-Plan-Role on AWS; the
  # runner's azure/login session on Azure). 6dae42f8-... is the AKS AAD server
  # application, the same in every tenant.
  exec = local.azure ? {
    command = "kubelogin"
    args    = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    } : {
    command = "aws"
    args    = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region, "--output", "json"]
  }
}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = local.found
      error_message = "core-platform state for ${var.env_id}/${var.region} has no cluster \"${var.cluster}\". Apply core-platform first, or fix `cluster` in the unit YAML."
    }
  }
}
