# State this module reads, from S3: the group's observability bucket and
# the cluster's istio gateways. The Azure slice defines the same names.
data "terraform_remote_state" "observability" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${module.context.group}-${local.config.observability_environment}/${local.region}/observability/terraform.tfstate"
  }
  defaults = {}
}

# The management cluster's internal gateway, for global_receiver's route.
data "terraform_remote_state" "istio" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/istio/terraform.tfstate"
  }
  defaults = {}
}
