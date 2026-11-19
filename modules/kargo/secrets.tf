# ── Management cluster: generate credentials on first apply ──────────────────

resource "random_password" "admin" {
  count            = local.is_management ? 1 : 0
  length           = 20
  special          = true
  override_special = "!@#%^&*()-_=+[]{}|"
}

resource "random_password" "token_signing_key" {
  count   = local.is_management ? 1 : 0
  length  = 32
  special = false
}

# ── Credential locals consumed by main.tf ────────────────────────────────────

locals {
  kargo_admin_password_hash = local.is_management ? local.slice.admin_password_hash : ""
  kargo_token_signing_key   = local.is_management ? local.slice.token_signing_key : ""
}
