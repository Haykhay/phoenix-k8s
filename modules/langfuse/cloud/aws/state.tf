# The group's observability bucket, from its S3 state. The Azure slice
# defines the same name.
data "terraform_remote_state" "observability" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${module.context.group}-${local.config.observability_environment}/${local.region}/observability/terraform.tfstate"
  }
  defaults = {}
}
