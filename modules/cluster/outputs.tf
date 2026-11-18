output "cluster_name" {
  description = "EKS or AKS cluster name."
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "API endpoint; a placeholder when core-platform has no such cluster (the plan then fails)."
  value       = try(local.cluster.cluster_endpoint, "https://cluster-missing.invalid")
}

output "cluster_ca_data" {
  description = "Base64 certificate authority data."
  value       = try(local.cluster.cluster_certificate_authority_data, "")
}

output "cluster_kms_key_arn" {
  description = "The cluster's KMS key."
  value       = try(local.cluster.cluster_kms_key_arn, null)
}

output "vpc_id" {
  description = "The cluster's VPC (AWS) or VNet ID (Azure)."
  value       = try(local.azure ? local.cluster.vnet_id : local.cluster.vpc_id, null)
}

output "node_subnet_ids" {
  description = "Subnets the cluster's nodes run in."
  value       = try(local.cluster.node_subnet_ids, [])
}

output "cluster_security_group_id" {
  description = "The EKS cluster security group (guards the API endpoint)."
  value       = try(local.cluster.cluster_security_group_id, null)
}

output "node_security_group_id" {
  description = "Node security group ID."
  value       = try(local.cluster.node_security_group_id, null)
}

output "karpenter" {
  description = "core-platform's Karpenter facts for this cluster, or null when it is not enabled."
  value       = try(local.cluster.karpenter, null)
}

output "dns" {
  description = "public/internal zone id and name of the cluster's zone, or null when the environment has none."
  value       = local.dns
}

output "dns_zones" {
  description = "Every hosted zone pair of the environment, keyed by name (dns unit's zones), or {}."
  value       = try(local.dns_outputs.zones, {})
}

# AKS facts, for workload identity and Key Vault bindings; null on AWS.
output "oidc_issuer_url" {
  description = "The AKS cluster's OIDC issuer (workload identity federation); null on AWS."
  value       = local.azure ? try(local.cluster.oidc_issuer_url, null) : null
}

output "key_vault_id" {
  description = "The environment's Key Vault (secrets); null on AWS."
  value       = local.azure ? try(local.cluster.key_vault_id, null) : null
}

output "node_resource_group" {
  description = "The AKS node resource group; null on AWS."
  value       = local.azure ? try(local.cluster.node_resource_group, null) : null
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity (image pulls); null on AWS."
  value       = local.azure ? try(local.cluster.kubelet_identity_object_id, null) : null
}

output "exec" {
  description = "Kubernetes/Helm provider exec block: a fresh token per call with the job's own credentials (aws eks get-token on AWS, kubelogin on Azure)."
  value = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = local.exec.command
    args        = local.exec.args
  }
}
