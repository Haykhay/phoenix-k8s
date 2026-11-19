# ── Spoke cluster: report to the environment's management cluster ────────────
# Same environment = same account and (assumed) same network, so no
# cross-account provider: the management cluster's facts come from
# core-platform's state, and its kargo unit's outputs and stored kubeconfig
# from the cloud slice (cloud/<cloud>/spoke_link.tf).

module "management_cluster" {
  source = "../cluster"

  cloud   = module.context.cloud
  state   = module.context.state
  env_id  = module.context.env_id
  region  = module.context.region
  cluster = local.management_cluster
}

# The namespace exists before helm_release.this (which waits on the secret below).
resource "kubernetes_namespace_v1" "kargo" {
  count = local.config.enabled ? 1 : 0
  metadata {
    name   = local.namespace
    labels = { name = local.namespace }
  }
}

resource "kubernetes_secret_v1" "kargo_management_kubeconfig" {
  count      = local.is_spoke ? 1 : 0
  depends_on = [kubernetes_namespace_v1.kargo]
  metadata {
    name      = "kargo-management-kubeconfig"
    namespace = local.namespace
  }
  data = {
    "kubeconfig.yaml" = local.slice.remote_kubeconfig
  }
}
