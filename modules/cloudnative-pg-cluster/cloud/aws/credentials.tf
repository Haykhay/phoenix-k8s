# Passwords and their Secrets Manager entries, on the platform's shared policy,
# at <organisation>/<env_id>/postgres/in-cluster/<instance>[/<database>] —
# where external-secrets may read them.
module "credentials" {
  source = "git::https://github.com/Haykhay/phoenix-aws.git//infrastructure/modules/credentials?ref=v1.1.0"

  organisation = local.organisation
  credentials  = local.credentials_requests
  publish      = local.credentials_publish
}
