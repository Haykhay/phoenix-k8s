output "url" {
  description = "Argo CD UI, on istio's internal gateway."
  value       = local.config.enabled ? "https://${local.hostname}" : null
}

output "repo_public_key" {
  description = "Add to the GitHub repository (spec.repo_url) as a read-only deploy key."
  value       = try(tls_private_key.repo[0].public_key_openssh, null)
}

output "resource_summary" {
  value = merge({
    environment   = local.environment
    region        = local.region
    cluster       = local.cluster_key
    resource_set  = "argo-cd"
    chart_version = try(helm_release.this[0].version, null)
  }, local.slice.summary)
}
