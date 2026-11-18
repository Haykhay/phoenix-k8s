variable "cloud" {
  description = "aws or azure (module.context.cloud)."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure"], var.cloud)
    error_message = "cloud must be aws or azure."
  }
}

variable "state" {
  description = "Backend settings (module.context.state). AWS: bucket, region, kms_key_id. Azure: subscription_id, resource_group, storage_account, container."
  type        = map(string)
}

variable "env_id" {
  description = "infrastructure environment (module.context.env_id)."
  type        = string
}

variable "region" {
  description = "Region of the cluster's core-platform unit."
  type        = string
}

variable "cluster" {
  description = "Key of the cluster in core-platform's clusters output, e.g. \"1\"."
  type        = string
}

variable "dns_zone" {
  description = "Key of the cluster's zone in the dns unit's zones output."
  type        = string
  default     = "zone-1"
}
