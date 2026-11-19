locals {
  defaults = {
    enabled  = true
    settings = {}
  }

  config = merge(local.defaults, module.context.spec)
}
