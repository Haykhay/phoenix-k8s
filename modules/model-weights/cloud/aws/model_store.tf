# The group's weights bucket and its copy role, from infrastructure's model-store unit.
data "terraform_remote_state" "model_store" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${module.context.group}-shared/${local.region}/model-store/terraform.tfstate"
  }
  defaults = {}
}
