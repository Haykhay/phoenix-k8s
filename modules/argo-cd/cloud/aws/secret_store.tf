# The admin password and deploy key, kept in Secrets Manager for humans.
resource "aws_secretsmanager_secret" "admin" {
  count                   = local.config.enabled ? 1 : 0
  name                    = "${local.secret_path}/admin"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin" {
  count     = local.config.enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.admin[0].id
  secret_string = jsonencode({
    password      = random_password.admin[0].result
    password_hash = bcrypt(random_password.admin[0].result)
  })

  lifecycle {
    # bcrypt() uses a random salt so the hash differs on every plan.
    # Freeze the value written on first apply; it never needs to change
    # unless the password is deliberately rotated (taint the resource).
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "repo_ssh" {
  count                   = local.config.enabled ? 1 : 0
  name                    = "${local.secret_path}/repo-ssh-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "repo_ssh" {
  count         = local.config.enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.repo_ssh[0].id
  secret_string = tls_private_key.repo[0].private_key_openssh
}

output "admin_secret" {
  description = "Secrets Manager secret holding the local admin password."
  value       = try(aws_secretsmanager_secret.admin[0].name, null)
}
