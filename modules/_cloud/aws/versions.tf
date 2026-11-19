# Merged with the module's own versions.tf when staged for AWS
# (scripts/stage-module).
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
