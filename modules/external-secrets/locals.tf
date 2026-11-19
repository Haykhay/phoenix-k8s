locals {
  defaults = {
    enabled       = true
    chart_version = "2.6.0"
    app_version   = ""
    settings      = {}
  }

  config = merge(local.defaults, module.context.spec)

  namespace            = "external-secrets"
  service_account_name = "external-secrets"
  role_name            = "${local.name_prefix}-external-secrets"

  # Everything this cluster may read lives under <organisation>/<env_id>/ in
  # its own account and region — the credentials module's publish path — so a
  # cluster can never read another environment's secrets.
  secret_path = "${local.organisation}/${local.environment}"
}
