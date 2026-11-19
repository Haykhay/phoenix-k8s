provider "aws" {
  region                      = local.region
  allowed_account_ids         = module.context.floci ? null : [local.account_id]
  skip_credentials_validation = module.context.floci
  skip_requesting_account_id  = module.context.floci
  skip_metadata_api_check     = module.context.floci

  default_tags {
    tags = merge(
      module.context.tags,
      { Cluster = local.cluster_key },
      local.instance == null ? {} : { Instance = local.instance },
    )
  }
}
