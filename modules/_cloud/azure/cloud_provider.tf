# The environment's managed identity (phoenix-<envId>, or -plan on pull
# requests), signed in over GitHub OIDC. Named by Backstage in the unit YAML.
provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = module.context.azure.subscription_id
  tenant_id       = module.context.azure.tenant_id
  client_id       = module.context.azure.client_id
}
