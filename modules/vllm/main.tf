# One served model per unit: vLLM on the model's GPU pool, an InferencePool
# (with its endpoint picker) over its pods, and an HTTPRoute on istio's
# internal gateway. Needs the cluster's istio unit and the karpenter-nodepool
# unit for the model's GPU type.
resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = !local.config.enabled || local.instance != null
      error_message = "vllm is per model: name the file vllm.<model slug>.yaml."
    }
    precondition {
      condition     = !local.config.enabled || (local.config.version != null && local.config.gpu != null)
      error_message = "spec.version (the model-weights version) and spec.gpu (GPU type) are required — Backstage fills both."
    }
    precondition {
      condition     = !local.config.enabled || contains(keys(local.hardware_profiles), local.config.hardware)
      error_message = "spec.hardware must be one of ${join(", ", sort(keys(local.hardware_profiles)))}."
    }
    precondition {
      condition     = !local.config.enabled || !can(data.terraform_remote_state.gpu_pool.outputs.node_pool) || local.config.hardware == local.pool_accelerator
      error_message = "spec.hardware is ${local.config.hardware} but pool gpu-${coalesce(local.config.gpu, "none")} is ${local.pool_accelerator}: pick a ${local.config.hardware} GPU type."
    }
    precondition {
      condition     = !local.config.enabled || local.config.gpu_memory_utilization == null || try(local.config.gpu_memory_utilization > 0 && local.config.gpu_memory_utilization <= 1, false)
      error_message = "spec.gpu_memory_utilization is a share of the GPU's memory: more than 0, at most 1."
    }
    precondition {
      condition     = !local.config.enabled || local.pool_time_slice == 0 || local.config.gpu_memory_utilization != null
      error_message = "pool gpu-${coalesce(local.config.gpu, "none")} shares each GPU ${local.pool_time_slice} ways: set spec.gpu_memory_utilization (at most ${format("%.2f", 1 / max(local.pool_time_slice, 1))}) so the models on one GPU fit its memory together."
    }
    precondition {
      condition     = !local.config.enabled || local.pool_time_slice == 0 || local.config.gpu_memory_utilization == null || try(local.config.gpu_memory_utilization * local.pool_time_slice <= 1, false)
      error_message = "spec.gpu_memory_utilization ${coalesce(local.config.gpu_memory_utilization, 0)} x ${local.pool_time_slice} shares is more than the GPU's memory: use at most ${format("%.2f", 1 / max(local.pool_time_slice, 1))}."
    }
    precondition {
      condition     = !local.config.enabled || local.pool_time_slice == 0 || (local.config.gpus_per_replica == 1 && local.config.nodes_per_replica == 1)
      error_message = "on a time-sliced pool a replica uses one share of one GPU: gpus_per_replica and nodes_per_replica must be 1."
    }
    precondition {
      condition     = !local.config.enabled || !local.shared || contains(["uat", "prod"], local.tier)
      error_message = "spec.access.consumers is for uat and prod only (consumers_only_uat_prod); ${local.tier} models serve their owner."
    }
    precondition {
      condition     = !local.config.enabled || length(local.owner_cidrs) > 0
      error_message = "no owner network for cluster ${local.cluster_key}: core-network has no VPC ${coalesce(module.cluster.vpc_id, "(unknown)")} and spec.access.owner_cidrs is empty. Access fails closed: a model is never open to the whole segment."
    }
    precondition {
      condition     = !local.config.enabled || alltrue([for name, c in local.access.consumers : length(try(c.cidrs, [])) > 0])
      error_message = "every consumer needs its environment's CIDRs; without them it could not call the model (consumers without CIDRs: ${join(", ", [for name, c in local.access.consumers : name if length(try(c.cidrs, [])) == 0])})."
    }
    precondition {
      condition     = !local.config.enabled || !local.oidc_on || local.oidc.jwks_uri != null
      error_message = "spec.access.oidc needs jwks_uri with issuer."
    }
    precondition {
      condition     = !local.config.enabled || !local.failover_on || contains(["PRIMARY", "SECONDARY"], try(local.failover.role, ""))
      error_message = "spec.failover.role must be PRIMARY or SECONDARY (one of each, in two clusters)."
    }
    precondition {
      condition     = !local.config.enabled || !local.failover_on || endswith(coalesce(local.failover_hostname, "-"), ".${local.failover_domain}")
      error_message = "spec.failover.hostname must be in the gateway's zone (${local.failover_domain}): its DNS, listener and certificate cover only that zone."
    }
    precondition {
      condition     = !local.config.enabled || !local.failover_on || can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", trimsuffix(coalesce(local.failover_hostname, "-"), ".${local.failover_domain}")))
      error_message = "spec.failover.hostname must be one label under ${local.failover_domain} (e.g. llama.${local.failover_domain}): the wildcard certificate covers one level."
    }
    precondition {
      condition     = !local.config.enabled || !local.failover_on || local.failover_hostname != lower(local.hostname)
      error_message = "spec.failover.hostname must differ from this cluster's own hostname (${local.hostname}): the clusters share it."
    }
    precondition {
      condition     = !local.config.enabled || alltrue([for name, rpm in local.rate_limited : try(rpm > 0 && floor(rpm) == rpm, false)])
      error_message = "spec.access.consumers[*].requests_per_minute must be a whole number of 1 or more (to stop a consumer, remove it from consumers)."
    }
    precondition {
      condition     = !local.config.enabled || !local.oidc_on || !local.rl_on
      error_message = "requests_per_minute works with network identity only, not with spec.access.oidc: rate limits key on the consumer the gateway stamps from the caller's CIDR."
    }
    precondition {
      condition     = !local.config.enabled || alltrue(values(local.option_checks))
      error_message = "spec.llm_d is invalid; failing checks: ${join(", ", [for k, ok in local.option_checks : k if !ok])}. llm-d options need hardware nvidia and the cluster's llm-d unit; wide_ep needs multi_node; multi_node needs nodes_per_replica >= 2 (and the reverse); multi_node, pd_disaggregation and wide_ep need an EFA pool; options must be in llm-d ${try(local.llm_d_state.version, "(not installed)")}'s supported_options (${join(", ", try(local.llm_d_state.supported_options, []))})."
    }
    precondition {
      # Null until the copy job has succeeded (model-weights publishes it then).
      condition     = !local.config.enabled || try(local.weights.cache_path, null) != null
      error_message = "no copied weights for ${local.slug} on cluster ${local.cluster_key}: apply model-weights.${local.slug} first (or fix its failed copy job)."
    }
    precondition {
      condition     = !local.config.enabled || try(local.weights.version, null) == null || try(local.weights.version == local.config.version, false)
      error_message = "spec.version is ${coalesce(local.config.version, "unset")} but model-weights.${local.slug} copied ${coalesce(try(local.weights.version, null), "nothing")}: apply that version's weights first, or pin the version it has."
    }
    precondition {
      condition     = !local.config.enabled || can(local.cache.pvc_name)
      error_message = "no model cache claim on cluster ${local.cluster_key}: apply ${local.slice.cache_driver} first."
    }
    precondition {
      condition     = !local.config.enabled || local.gateway != null
      error_message = "no istio internal gateway for cluster ${local.cluster_key}: apply the cluster's istio unit first."
    }
    precondition {
      condition     = !local.config.enabled || can(data.terraform_remote_state.gpu_pool.outputs.node_pool)
      error_message = "no GPU pool \"${coalesce(local.config.gpu, "none")}\" on cluster ${local.cluster_key}: apply karpenter-nodepool.${coalesce(local.config.gpu, "none")} first."
    }
  }
}

# Default path: the Inference Extension's endpoint picker. Any llm-d option
# swaps it for the llm-d router (llm_d.tf), under the same pool name.
resource "helm_release" "pool" {
  count            = local.config.enabled && !local.llm_d_any ? 1 : 0
  name             = local.pool_name
  repository       = "oci://registry.k8s.io/gateway-api-inference-extension/charts"
  chart            = "inferencepool"
  version          = local.config.pool_chart
  namespace        = local.namespace
  create_namespace = true

  values = [yamlencode({
    inferencePool = {
      modelServers    = { matchLabels = { app = local.server } }
      targetPorts     = [{ number = 8000 }]
      modelServerType = "vllm"
    }
    provider = { name = "istio" }
    # The chart's default (4 CPU / 8Gi) is sized for large fleets.
    inferenceExtension = {
      resources = { requests = { cpu = "500m", memory = "1Gi" }, limits = { memory = "2Gi" } }
    }
  })]

  depends_on = [terraform_data.validation]
}

resource "helm_release" "server" {
  count     = local.config.enabled ? 1 : 0
  name      = local.server
  chart     = "${path.module}/manifests/vllm"
  namespace = local.namespace
  timeout   = 1800 # model download + load

  values = [yamlencode(merge({
    name           = local.server
    modelPath      = local.cache_path
    servedName     = local.served_name
    startupSeconds = local.startup_seconds
    cache = {
      claim     = try(local.cache.pvc_name, "")
      mountPath = try(local.cache.mount_path, "")
      subPath   = try(local.cache.sub_path, "")
    }
    prepull        = true
    replicas       = local.config.replicas
    maxModelLen    = local.config.max_model_len
    extraArgs      = concat(local.memory_args, local.config.extra_args)
    image          = local.efa_on ? local.slice.fabric_image : local.hardware.image
    command        = local.hardware.command
    accelerator    = local.hardware.accelerator
    tensorParallel = coalesce(local.config.tensor_parallel_size, local.config.gpus_per_replica)
    gpu            = { type = local.config.gpu, perReplica = local.config.gpus_per_replica }
    route = {
      hostname = local.hostname
      gateway  = { name = try(local.gateway.name, ""), namespace = try(local.gateway.namespace, "") }
      failover = local.failover_on ? { hostname = local.failover_hostname, role = try(local.failover.role, ""), setIdentifier = local.name_prefix } : null
      pool     = local.pool_name
    }
    }, concat(
    [for v in [{ llmD = local.llm_d_values }] : v if local.llm_d_any],
    [for v in [{ access = local.access_values }] : v if local.access_on],
  )...))]

  depends_on = [helm_release.pool, helm_release.router]
}
