output "mode" {
  description = "management or spoke."
  value       = local.config.enabled ? local.mode : null
}

output "shard" {
  description = "This cluster's shard name (<env_id>-<cluster>)."
  value       = local.shard
}

output "url" {
  description = "Kargo UI; management cluster only."
  value       = local.is_management ? "https://${local.api_host}" : null
}

output "resource_summary" {
  value = {
    environment   = local.environment
    region        = local.region
    cluster       = local.cluster_key
    resource_set  = "kargo"
    mode          = local.mode
    chart_version = local.config.chart_version
  }
}
