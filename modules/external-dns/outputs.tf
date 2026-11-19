output "zone_ids" {
  description = "Hosted zones it reconciles (and may write to)."
  value       = local.zone_ids
}

output "resource_summary" {
  value = {
    environment   = local.environment
    region        = local.region
    cluster       = local.cluster_key
    resource_set  = "external-dns"
    chart_version = try(helm_release.this[0].version, null)
    txt_owner_id  = local.txt_owner_id
  }
}
