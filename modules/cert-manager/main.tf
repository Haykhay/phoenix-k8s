resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = !local.config.enabled || local.dns != null
      error_message = "cert-manager's issuers need the cluster's DNS zone from infrastructure's dns unit for ${local.environment}."
    }
  }
}

resource "helm_release" "this" {
  count            = local.config.enabled ? 1 : 0
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = local.config.chart_version
  namespace        = local.namespace
  create_namespace = true

  values = [yamlencode(merge(
    {
      crds           = { enabled = local.install_crds }
      config         = { enableGatewayAPI = local.enable_gateway_api }
      serviceAccount = { name = local.service_account_name, annotations = local.slice.service_account_annotations }
    },
    local.config.app_version == "" ? {} : { image = { tag = local.config.app_version } },
  ))]

  depends_on = [terraform_data.validation, terraform_data.slice_ready]
}

# Let's Encrypt prod + staging, DNS-01 in the cluster's zones (the solver is
# the cloud slice's).
resource "helm_release" "cluster_issuers" {
  count     = local.config.enabled ? 1 : 0
  name      = "cert-manager-cluster-issuers"
  chart     = "${path.module}/manifests/cluster-issuers"
  namespace = local.namespace

  values = [yamlencode({
    acmeEmail        = local.acme_email
    publicZoneName   = try(local.dns.public_zone_name, "")
    internalZoneName = try(local.dns.internal_zone_name, "")
    dns01            = local.slice.dns01_solver
  })]

  depends_on = [helm_release.this]
}
