# AWS slice (staged in by scripts/stage-module).
locals {
  slice = {
    # OpenCost detects AWS and uses its public list prices: nothing to set.
    pricing_values = {}
  }
}
