# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # Management: Kargo's admin credentials, frozen in Secrets Manager at
    # first apply (secret_store.tf).
    admin_password_hash = local.is_management ? jsondecode(aws_secretsmanager_secret_version.admin[0].secret_string)["ADMIN_ACCOUNT_PASSWORD_HASH"] : ""
    token_signing_key   = local.is_management ? jsondecode(aws_secretsmanager_secret_version.admin[0].secret_string)["ADMIN_ACCOUNT_TOKEN_SIGNING_KEY"] : ""
    # Spoke: the kubeconfig the management cluster stored (spoke_link.tf).
    remote_kubeconfig = local.is_spoke ? data.aws_secretsmanager_secret_version.remote_kubeconfig[0].secret_string : ""
  }

  # Spoke: the management cluster's kargo unit outputs ({} until applied).
  # Its own local, not a slice key: the validation reads it, and the stored
  # kubeconfig is read only after the validation (a single local would cycle).
  management_outputs = try(data.terraform_remote_state.management[0].outputs, {})
}

# The release waits on this: Pod Identity has had time to propagate (iam.tf).
resource "terraform_data" "slice_ready" {
  depends_on = [time_sleep.pod_identity_propagation]
}
