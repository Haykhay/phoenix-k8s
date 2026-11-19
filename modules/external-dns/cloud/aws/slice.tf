# AWS slice (staged in by scripts/stage-module): Route 53 through Pod Identity.
locals {
  slice = {
    # Pod Identity binds the role to the service account: no annotation.
    service_account_annotations = {}
    # Chart values for the DNS provider, merged into the release's values.
    provider_values = {
      provider = { name = "aws" }
      # The chart has no zoneIdFilters value; the filter is container args.
      extraArgs = [for id in local.zone_ids : "--zone-id-filter=${id}"]
      env       = [{ name = "AWS_DEFAULT_REGION", value = local.region }]
    }
  }
}

# The release waits on this: the role is attached and Pod Identity has had
# time to propagate (iam.tf).
resource "terraform_data" "slice_ready" {
  depends_on = [aws_iam_role_policy_attachment.this, time_sleep.pod_identity_propagation]
}

output "role_arn" {
  description = "IAM role its service account uses, through Pod Identity."
  value       = try(aws_iam_role.this[0].arn, null)
}
