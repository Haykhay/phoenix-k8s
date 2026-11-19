# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # Credentials live in Secrets Manager (credentials.tf); ExternalSecrets read
    # them through external-secrets' store.
    secret_store = "aws-secretsmanager"
  }
}
