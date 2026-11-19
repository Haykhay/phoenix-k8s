# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # The read-only claim on the cluster's FSx model cache (state.tf).
    cache_claim  = try(data.terraform_remote_state.fsx.outputs, {})
    cache_driver = "aws-fsx-csi-driver"
    # Multi-node and disaggregated serving over EFA: the AWS vLLM DLC with EFA
    # (llm-d v0.10.0's aws-efa image).
    fabric_image = { repository = "public.ecr.aws/deep-learning-containers/vllm", tag = local.config.efa_image_tag }
    # Accelerators besides nvidia.
    accelerators = {
      neuron = {
        image       = { repository = "public.ecr.aws/neuron/pytorch-inference-vllm-neuronx", tag = local.config.neuron_image_tag }
        accelerator = { resource = "aws.amazon.com/neuron", taint = "aws.amazon.com/neuron" }
        # Its entrypoint runs whatever command it is given.
        command = ["python", "-m", "vllm.entrypoints.openai.api_server"]
      }
    }
  }
}
