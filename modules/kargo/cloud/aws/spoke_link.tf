# Spoke cluster: the management cluster's kargo unit (state in S3), the
# kubeconfig it stored, and API access for this spoke's nodes.
data "terraform_remote_state" "management" {
  count   = local.is_spoke ? 1 : 0
  backend = "s3"
  config = {
    bucket = module.context.state.bucket
    region = module.context.state.region
    key    = "${local.environment}/${local.region}/k8s/${local.management_cluster}/kargo/terraform.tfstate"
  }
  defaults = {}
}

data "aws_secretsmanager_secret_version" "remote_kubeconfig" {
  count     = local.is_spoke ? 1 : 0
  secret_id = try(data.terraform_remote_state.management[0].outputs.remote_kubeconfig_secret, "kargo-management-missing")

  depends_on = [terraform_data.validation]
}

# This spoke's nodes (only) may reach the management cluster's API. One rule
# per spoke, keyed by its own node security group, so spokes never collide.
resource "aws_security_group_rule" "management_api_access" {
  count                    = local.is_spoke ? 1 : 0
  type                     = "ingress"
  security_group_id        = module.management_cluster.cluster_security_group_id
  source_security_group_id = module.cluster.node_security_group_id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Kargo spoke ${local.shard} to the management cluster API"
}
