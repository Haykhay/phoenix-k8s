# Merged with the module's own versions.tf when staged for Azure
# (scripts/stage-module).
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
