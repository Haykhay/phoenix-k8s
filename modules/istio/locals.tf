locals {
  defaults = {
    enabled       = true
    chart_version = "1.30.1"
    settings      = {}
  }

  config    = merge(local.defaults, module.context.spec)
  namespace = "istio-system"
  dns       = module.cluster.dns

  public_zone_name   = try(local.dns.public_zone_name, "dns-missing")
  internal_zone_name = try(local.dns.internal_zone_name, "dns-missing")

  public_secret_name   = "wildcard-istio-public-tls"
  internal_secret_name = "wildcard-istio-internal-tls"

  internal_gateway = {
    enabled = try(local.config.settings.gateways.internal.enabled, true)
    # The cloud's load balancer for each gateway (cloud/<cloud>/slice.tf).
    service_annotations = merge(
      local.slice.gateway_service_annotations.internal,
      try(local.config.settings.gateways.internal.service_annotations, {}),
    )
  }

  external_gateway = {
    enabled = try(local.config.settings.gateways.external.enabled, false)
    service_annotations = merge(
      local.slice.gateway_service_annotations.public,
      try(local.config.settings.gateways.external.service_annotations, {}),
    )
  }
}
