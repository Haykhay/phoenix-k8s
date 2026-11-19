# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # Pod Identity binds argocd-repo-server to its role: no annotation.
    service_account_annotations = {}
    # bcrypt hash of the admin password, frozen at first apply (secrets.tf).
    admin_password_hash = local.config.enabled ? jsondecode(aws_secretsmanager_secret_version.admin[0].secret_string)["password_hash"] : ""
    summary             = { role_arn = try(aws_iam_role.repo_server[0].arn, null) }
  }
}

# The release waits on this: Pod Identity has had time to propagate (iam.tf).
resource "terraform_data" "slice_ready" {
  depends_on = [time_sleep.pod_identity_propagation]
}
