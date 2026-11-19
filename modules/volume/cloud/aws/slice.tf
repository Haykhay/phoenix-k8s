# AWS slice (staged in by scripts/stage-module): phoenix-shared is FSx for
# Lustre (aws-fsx-csi-driver).
locals {
  slice = {
    # FSx for Lustre PERSISTENT_2: 1200 GiB, then steps of 2400 GiB.
    shared_size_valid = local.size_set && (local.size == 1200 || try(local.size % 2400 == 0, false))
    shared_size_rule  = "1200 GiB or a multiple of 2400 GiB (FSx for Lustre)"
  }
}
