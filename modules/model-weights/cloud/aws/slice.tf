# AWS slice (staged in by scripts/stage-module): weights land in the group's
# S3 bucket, copied with model-store's writer role through Pod Identity.
locals {
  slice = {
    # Pod Identity binds the job's service account (iam.tf): no annotation.
    service_account_annotations = {}
    # model-store's outputs (model_store.tf): bucket_name, writer_role_arn.
    store = try(data.terraform_remote_state.model_store.outputs, {})
    # The copy job's upload step. Its commands are still the chart's (aws s3).
    copy_job = { image = "amazon/aws-cli:2.38.0" } # 2026-10-13
  }

  s3_prefix = "s3://${local.bucket}/${local.key}/"
}

# The job waits on this: Pod Identity has had time to propagate (iam.tf).
resource "terraform_data" "slice_ready" {
  depends_on = [time_sleep.pod_identity_propagation]
}

output "s3_prefix" {
  description = "Copied weights: s3://<bucket>/<model>/<version>/, complete once _COMPLETE exists."
  value       = local.copied ? local.s3_prefix : null
}
