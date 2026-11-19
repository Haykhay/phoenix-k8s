# Pulls of OCI charts from the group account's ECR pull-through cache: the
# repo server's role may read these repositories (iam.tf).
locals {
  ecr_pull_arns = concat(
    ["arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.config.ecr_cache_prefix}/*"],
    [for repo in try(local.config.settings.extra_ecr_pull_repos, []) : "arn:aws:ecr:${local.region}:${local.account_id}:repository/${repo}"],
  )
}

# OCI Helm repository credentials for the group account's ECR (pull-through cache).
resource "helm_release" "ecr_credentials" {
  count     = local.config.enabled ? 1 : 0
  name      = "argocd-ecr-credentials"
  chart     = "${path.module}/manifests/ecr-credentials"
  namespace = local.namespace

  values = [yamlencode({ region = local.region, accountIds = [local.account_id] })]

  depends_on = [helm_release.this]
}
