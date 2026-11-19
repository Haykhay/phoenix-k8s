# AWS slice (staged in by scripts/stage-module).
data "aws_vpc" "cluster" {
  id = module.cluster.vpc_id
}

locals {
  slice = {
    # Chaining with the AWS VPC CNI: pods keep VPC addresses (IPAM planning
    # and transit gateway routing are unchanged); Cilium only enforces policy.
    values = {
      cni = {
        chainingMode = "aws-cni"
        exclusive    = false
      }
      enableIPv4Masquerade = false
      routingMode          = "native"
      kubeProxyReplacement = false
      endpointRoutes       = { enabled = true }
    }
    # The cluster's own network, open to every pod.
    cluster_cidrs = [data.aws_vpc.cluster.cidr_block]
    # Pod Identity agent and instance metadata.
    metadata_cidrs = ["169.254.170.23/32", "169.254.169.254/32"]
  }
}
