locals {
  defaults = {
    enabled       = true
    namespace     = null # where the pods that mount it run (created if missing)
    storage_class = "phoenix-block"
    size_gib      = null
  }

  config = merge(local.defaults, module.context.spec)

  # The platform's cloud-neutral classes (cluster-config, and the cloud's
  # shared file system driver).
  access_modes      = { "phoenix-block" = "ReadWriteOnce", "phoenix-shared" = "ReadWriteMany" }
  system_namespaces = ["kube-system", "kube-public", "kube-node-lease", "default"]

  size     = try(tonumber(local.config.size_gib), null)
  size_set = local.size != null && try(local.size > 0 && floor(local.size) == local.size, false)
}
