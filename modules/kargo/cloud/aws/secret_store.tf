# Management cluster: Kargo's admin credentials, generated on first apply and
# kept in Secrets Manager.
resource "aws_secretsmanager_secret" "admin" {
  count                   = local.is_management ? 1 : 0
  name                    = "${local.secret_path}/admin"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin" {
  count     = local.is_management ? 1 : 0
  secret_id = aws_secretsmanager_secret.admin[0].id
  secret_string = jsonencode({
    password                        = random_password.admin[0].result
    ADMIN_ACCOUNT_PASSWORD_HASH     = bcrypt(random_password.admin[0].result)
    ADMIN_ACCOUNT_TOKEN_SIGNING_KEY = random_password.token_signing_key[0].result
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Management cluster: the kubeconfig spokes use to report to it.
resource "aws_secretsmanager_secret" "remote_kubeconfig" {
  count                   = local.is_management ? 1 : 0
  name                    = "${local.secret_path}/remote-kubeconfig"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "remote_kubeconfig" {
  count     = local.is_management ? 1 : 0
  secret_id = aws_secretsmanager_secret.remote_kubeconfig[0].id

  secret_string = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "management"
      cluster = {
        certificate-authority-data = module.cluster.cluster_ca_data
        server                     = module.cluster.cluster_endpoint
      }
    }]
    contexts = [{
      name = "management"
      context = {
        cluster = "management"
        user    = kubernetes_service_account_v1.spoke_agent[0].metadata[0].name
      }
    }]
    current-context = "management"
    users = [{
      name = kubernetes_service_account_v1.spoke_agent[0].metadata[0].name
      user = {
        token = kubernetes_secret_v1.spoke_agent_token[0].data["token"]
      }
    }]
  })

  lifecycle {
    ignore_changes       = [secret_string]
    replace_triggered_by = [kubernetes_secret_v1.spoke_agent_token]
  }
}

output "remote_kubeconfig_secret" {
  description = "Management only: Secrets Manager secret with the kubeconfig spokes use. Spokes read this from this unit's state."
  value       = try(aws_secretsmanager_secret.remote_kubeconfig[0].name, null)
}
