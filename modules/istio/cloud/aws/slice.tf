# AWS slice (staged in by scripts/stage-module): gateways get an NLB from
# aws-load-balancer-controller (IP targets).
locals {
  nlb_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  }

  slice = {
    gateway_service_annotations = {
      internal = merge(local.nlb_annotations, {
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
        # IP targets don't keep the caller's address by default; model access
        # (vllm spec.access) is decided by it.
        "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = "preserve_client_ip.enabled=true"
      })
      public = merge(local.nlb_annotations, {
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      })
    }
  }
}
