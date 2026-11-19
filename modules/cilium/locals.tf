locals {
  defaults = {
    enabled       = true
    chart_version = "1.20.2"
    settings      = {}
  }

  config = merge(local.defaults, module.context.spec)

  namespace       = "kube-system"
  release_name    = try(local.config.settings.release_name, "cilium")
  chart           = try(local.config.settings.chart, "cilium")
  repository      = try(local.config.settings.repository, "https://helm.cilium.io/")
  chart_version   = try(local.config.settings.chart_version, local.config.chart_version)
  chart_values    = merge(local.slice.values, coalesce(try(local.config.settings.values, null), {}))
  wait            = try(local.config.settings.wait, true)
  timeout         = try(local.config.settings.timeout, 600)
  atomic          = try(local.config.settings.atomic, true)
  cleanup_on_fail = try(local.config.settings.cleanup_on_fail, true)

  # Default egress for every pod: its own network, the shared segment (tooling
  # network, hub DNS), the cloud's metadata endpoints, DNS, and the internet.
  # Everything else private (other environments, on-prem) is denied unless
  # egress_allow or a team's namespaced CiliumNetworkPolicy opens it.
  egress_allow = try(local.config.settings.egress_allow, {})
  policy_values = {
    allowCidrs = concat(
      local.slice.cluster_cidrs,
      [try(module.context.platform_network.segments.shared, null)],
      local.slice.metadata_cidrs,
      try(local.egress_allow.cidrs, []),
    )
    # Internet = outside RFC 1918 and outside on-prem (whose ranges need not
    # be RFC 1918).
    internetExcept = distinct(concat(["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"], try(module.context.platform_network.onprem_cidrs, [])))
    allowFqdns     = try(local.egress_allow.fqdns, [])
  }
}
