resource "helm_release" "this" {
  count            = local.config.enabled ? 1 : 0
  name             = "external-secrets"
  chart            = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  version          = local.config.chart_version
  namespace        = local.namespace
  create_namespace = true

  wait    = true
  timeout = 600

  values = [
    templatefile("${path.module}/manifests/values.yaml.tpl", {
      service_account_name = local.service_account_name
      app_version          = try(local.config.app_version, "")
      sa_annotations       = local.slice.service_account_annotations
    })
  ]

  set = [{ name = "installCRDs", value = "true" }]

  depends_on = [terraform_data.slice_ready]
}

resource "helm_release" "cluster_secret_stores" {
  count     = local.config.enabled ? 1 : 0
  name      = "external-secrets-cluster-secret-stores"
  chart     = local.slice.cluster_secret_store.chart
  namespace = local.namespace

  set = local.slice.cluster_secret_store.set

  depends_on = [helm_release.this]
}
