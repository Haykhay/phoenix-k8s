# AWS slice (staged in by scripts/stage-module): DNS-01 through Route 53,
# with Pod Identity.
locals {
  # The zones the role may change (iam.tf).
  hosted_zone_arns = coalesce(try(local.config.settings.hosted_zone_arns, null), [
    "arn:aws:route53:::hostedzone/${try(local.dns.public_zone_id, "dns-missing")}",
    "arn:aws:route53:::hostedzone/${try(local.dns.internal_zone_id, "dns-missing")}",
  ])

  slice = {
    # Pod Identity binds the role to the service account: no annotation.
    service_account_annotations = {}
    # The ClusterIssuers' DNS-01 solver for each of the cluster's zones.
    dns01_solver = {
      public   = { route53 = { region = local.region, hostedZoneID = try(local.dns.public_zone_id, "") } }
      internal = { route53 = { region = local.region, hostedZoneID = try(local.dns.internal_zone_id, "") } }
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
