resource "helm_release" "this" {
  count            = local.config.enabled ? 1 : 0
  name             = "cluster-config"
  chart            = "${path.module}/manifests/cluster-config"
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 120
  atomic           = true
  cleanup_on_fail  = true

  # The cloud's default StorageClass (gp3 on AWS), from the slice.
  values = [yamlencode(local.slice.default_class_values)]
}

# phoenix-block: the platform's cloud-neutral name for a pod's own disk. Every
# cloud maps it to its encrypted block storage (the slice's block_class);
# workloads ask for the name, never the cloud's class. The cloud's own default
# class stays the default.
resource "kubernetes_storage_class_v1" "block" {
  count = local.config.enabled ? 1 : 0

  metadata {
    name = "phoenix-block"
  }

  storage_provisioner    = local.slice.block_class.provisioner
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  parameters             = local.slice.block_class.parameters
}
