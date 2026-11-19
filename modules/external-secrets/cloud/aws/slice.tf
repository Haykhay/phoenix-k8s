# AWS slice (staged in by scripts/stage-module): Secrets Manager and SSM
# through Pod Identity.
locals {
  # What the operator's role may read (iam.tf): only this environment's path.
  secrets_manager_arns = try(local.config.settings.secrets_manager_arns, [
    "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${local.secret_path}/*",
  ])
  ssm_parameter_arns = try(local.config.settings.ssm_parameter_arns, [
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${local.secret_path}/*",
  ])
  kms_key_arns = distinct(compact(concat(
    [module.cluster.cluster_kms_key_arn],
    try(local.config.settings.kms_key_arns, []),
  )))
  # Repositories in this account the operator may pull from (e.g. OCI Helm
  # charts behind the ECR pull-through cache), as repository names.
  ecr_pull_repos = try(local.config.settings.ecr_pull_repos, [])

  slice = {
    # Pod Identity binds the role to the service account: no annotation.
    service_account_annotations = {}
    # The ClusterSecretStores: a local chart, its values, and the store names
    # an ExternalSecret references.
    cluster_secret_store = {
      chart = "${path.module}/manifests/cluster-secret-stores"
      set   = [{ name = "awsRegion", value = local.region }]
      names = ["aws-secretsmanager", "aws-ssm"]
    }
    summary = { role_arn = try(aws_iam_role.this[0].arn, null) }
  }
}

# The operator waits on this: the role is attached and Pod Identity has had
# time to propagate (iam.tf).
resource "terraform_data" "slice_ready" {
  depends_on = [aws_iam_role_policy_attachment.this, time_sleep.pod_identity_propagation]
}

output "role_arn" {
  description = "Pod Identity role of the operator."
  value       = try(aws_iam_role.this[0].arn, null)
}
