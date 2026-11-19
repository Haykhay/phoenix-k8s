resource "random_password" "admin" {
  count            = local.config.enabled ? 1 : 0
  length           = 20
  special          = true
  override_special = "!@#%^&*()-_=+[]{}|"
}

resource "tls_private_key" "repo" {
  count     = local.config.enabled ? 1 : 0
  algorithm = "ED25519"
}

locals {
  argocd_admin_password_hash  = local.config.enabled ? local.slice.admin_password_hash : ""
  argocd_repo_ssh_private_key = local.config.enabled ? tls_private_key.repo[0].private_key_openssh : ""
}
