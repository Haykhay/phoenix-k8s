# Partial: the workflow supplies the environment's state storage account,
# container and key (module.context.state), with OIDC and Entra auth.
terraform {
  backend "azurerm" {}
}
