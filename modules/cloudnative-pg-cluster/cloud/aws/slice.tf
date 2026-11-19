# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # Credentials live in Secrets Manager (credentials.tf); ExternalSecrets read
    # them through external-secrets' store.
    secret_store = "aws-secretsmanager"
    # The internal load balancer in front of the rw service (spec.nlb_enabled):
    # an NLB from aws-load-balancer-controller, IP targets.
    lb_annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internal"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
    }
  }
}
