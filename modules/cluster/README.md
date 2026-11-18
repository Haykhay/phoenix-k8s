# cluster

Shared lookup, not a component: every phoenix-k8s root calls it to find the
EKS or AKS cluster its unit targets. It reads infrastructure's state for the
same environment, from S3 on AWS or the environment's blob container on Azure
(`cloud`, default `aws`):

| State | Key | Gives |
|---|---|---|
| core-platform | `<env_id>/<region>/core-platform/terraform.tfstate` | cluster name, endpoint, CA, KMS key, VPC/VNet, node subnets, node SG, Karpenter facts; on Azure also the OIDC issuer, Key Vault, node resource group, kubelet identity |
| dns (optional) | `<env_id>/global/dns/terraform.tfstate` | the cluster's zone (`dns_zone`, default `zone-1`) |

A missing core-platform state or an unknown cluster key fails the plan on
`terraform_data.validation` with a message naming both — before any Helm or
Kubernetes provider call (they get a placeholder endpoint meanwhile).
`dns` is `null` when the environment has no dns unit; components that need a
zone check for that themselves.

The helm and kubernetes providers take a fresh token per call from `exec`
(see `_boilerplate`), not a token fetched once: that one expires after 15
minutes, shorter than some Helm waits. `exec` uses the job's own credentials:

- AWS: `aws eks get-token --cluster-name <name> --region <region>`
  (Terraform-Role, or Terraform-Plan-Role for a plan);
- Azure: `kubelogin get-token --login azurecli --server-id 6dae42f8-…`, on the
  runner's `azure/login` session.

On Azure, core-platform's `clusters[<key>]` must carry `cluster_name`,
`cluster_endpoint`, `cluster_certificate_authority_data`, `oidc_issuer_url`,
`node_resource_group`, `vnet_id`, `node_subnet_ids`, `key_vault_id`,
`kubelet_identity_object_id` and `nap`. `vpc_id` returns the VNet ID there;
`oidc_issuer_url`, `key_vault_id`, `node_resource_group` and
`kubelet_identity_object_id` are `null` on AWS.

```hcl
module "cluster" {
  source   = "../cluster"
  cloud    = module.context.cloud
  state    = module.context.state
  env_id   = module.context.env_id
  region   = module.context.region
  cluster  = module.context.config.cluster
  dns_zone = try(module.context.config.dns_zone, "zone-1")
}
```

Tests override its reads at `module.cluster.data.terraform_remote_state.core_platform[0]`
and `.dns[0]` (AWS), or `.core_platform_azure[0]` and `.dns_azure[0]` (Azure).
