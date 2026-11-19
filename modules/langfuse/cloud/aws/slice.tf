# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # The chart's s3 block for S3. Credentials come from Pod Identity
    # (langfuse/langfuse, bound by core-platform), not keys.
    object_storage = {
      storageProvider = "s3"
      bucket          = local.bucket
      region          = local.region
      # Real S3: virtual-hosted addressing (path style is for S3-compatible stores).
      forcePathStyle = false
    }
  }
}
