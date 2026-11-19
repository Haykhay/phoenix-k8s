# AWS slice (staged in by scripts/stage-module): EBS through the EBS CSI driver.
locals {
  # The tags every AWS resource of this unit carries; EBS volumes created
  # through gp3 and phoenix-block get the same.
  ebs_tags = merge(
    module.context.tags,
    { Cluster = local.cluster_key },
  )

  slice = {
    # The chart's default class: gp3, encrypted, tagged.
    default_class_name   = "gp3"
    default_class_values = { ebs = { enabled = true }, tags = local.ebs_tags }
    # phoenix-block: encrypted gp3, volumes tagged like the unit.
    block_class = {
      provisioner = "ebs.csi.aws.com"
      parameters = merge(
        { type = "gp3", encrypted = "true" },
        { for i, k in sort(keys(local.ebs_tags)) : "tagSpecification_${i + 1}" => "${k}=${local.ebs_tags[k]}" },
      )
    }
  }
}
