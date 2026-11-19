# State this module reads, from S3. The Azure slice defines the same names.

data "terraform_remote_state" "istio" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/istio/terraform.tfstate"
  }
  defaults = {}
}

data "terraform_remote_state" "gpu_pool" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/karpenter-nodepool.${coalesce(local.config.gpu, "none")}/terraform.tfstate"
  }
  defaults = {}
}

# The model's weights, copied by model-weights.<slug> on this cluster.
data "terraform_remote_state" "weights" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/model-weights.${local.slug}/terraform.tfstate"
  }
  defaults = {}
}

# The read-only claim on the cluster's FSx model cache.
data "terraform_remote_state" "fsx" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/aws-fsx-csi-driver/terraform.tfstate"
  }
  defaults = {}
}

# The environment's VPCs: the cluster's own VPC CIDR is the owner's identity
# when spec.access.owner_cidrs is empty.
data "terraform_remote_state" "core_network" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/core-network/terraform.tfstate"
  }
  defaults = {}
}

# The cluster's llm-d prerequisites: needed only when an llm-d option is on.
data "terraform_remote_state" "llm_d" {
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.cluster_key}/llm-d/terraform.tfstate"
  }
  defaults = {}
}
