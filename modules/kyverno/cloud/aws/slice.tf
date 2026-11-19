# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # Any ECR image counts as internal, and internal images must come from the
    # group account's own registry (its pull-through cache).
    registry_patterns = {
      managed = ["*.dkr.ecr.*.amazonaws.com/*"]
      allowed = ["${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/*"]
    }
    # Accelerators a quota can count, and the resource each one requests.
    quota_keys = {
      nvidia = "requests.nvidia.com/gpu"
      neuron = "requests.aws.amazon.com/neuron"
    }
  }
}
