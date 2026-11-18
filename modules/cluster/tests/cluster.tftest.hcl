mock_provider "aws" {}

variables {
  state   = { bucket = "acme-tfstate-111111111111", region = "eu-west-1" }
  env_id  = "research-sandbox"
  region  = "eu-west-1"
  cluster = "1"
}

override_data {
  target = data.terraform_remote_state.core_platform[0]
  values = {
    outputs = {
      clusters = {
        "1" = {
          cluster_name                       = "research-sandbox-euw1-1-eks"
          cluster_endpoint                   = "https://ABC.gr7.eu-west-1.eks.amazonaws.com"
          cluster_certificate_authority_data = "Q0EtREFUQQ=="
          cluster_kms_key_arn                = "arn:aws:kms:eu-west-1:111111111111:key/1234"
          node_security_group_id             = "sg-123"
          cluster_security_group_id          = "sg-cluster-1"
          vpc_id                             = "vpc-123"
          node_subnet_ids                    = ["subnet-p1", "subnet-p2"]
          karpenter                          = null
        }
      }
    }
  }
}

override_data {
  target = data.terraform_remote_state.dns[0]
  values = {
    outputs = {
      zones = {
        "zone-1" = {
          public_zone_id     = "Z1PUB"
          public_zone_name   = "sandbox.research.example.com"
          internal_zone_id   = "Z1INT"
          internal_zone_name = "internal.sandbox.research.example.com"
        }
      }
    }
  }
}

run "finds_cluster" {
  command = plan

  assert {
    condition     = output.cluster_name == "research-sandbox-euw1-1-eks"
    error_message = "cluster 1's name comes from core-platform's clusters output"
  }
  assert {
    condition     = output.vpc_id == "vpc-123" && output.cluster_ca_data == "Q0EtREFUQQ=="
    error_message = "VPC and CA come from the same cluster entry"
  }
  assert {
    condition     = length(output.node_subnet_ids) == 2 && output.node_subnet_ids[0] == "subnet-p1"
    error_message = "node subnets come from the same cluster entry"
  }
  assert {
    condition     = output.cluster_security_group_id == "sg-cluster-1"
    error_message = "the EKS cluster security group, for components that open the API to other clusters"
  }
  assert {
    condition     = output.dns.public_zone_name == "sandbox.research.example.com"
    error_message = "the cluster's DNS zone is zone-1 by default"
  }
  assert {
    condition     = keys(output.dns_zones) == ["zone-1"]
    error_message = "every zone of the environment is exposed, for components that may span zones"
  }
}

run "unknown_cluster_rejected" {
  command = plan

  variables {
    cluster = "9"
  }

  expect_failures = [terraform_data.validation]
}

run "missing_core_platform_rejected" {
  command = plan

  override_data {
    target = data.terraform_remote_state.core_platform[0]
    values = { outputs = {} }
  }

  expect_failures = [terraform_data.validation]
}

run "dns_optional" {
  command = plan

  override_data {
    target = data.terraform_remote_state.dns[0]
    values = { outputs = {} }
  }

  assert {
    condition     = output.dns == null
    error_message = "an environment without a dns unit gives dns = null, not an error"
  }
}

# Providers sign in to the cluster with the job's own credentials
# (Terraform-Role or Terraform-Plan-Role): no --role-arn.
run "exec_without_role_arn" {
  command = plan

  assert {
    condition     = output.exec.command == "aws" && output.exec.args == tolist(["eks", "get-token", "--cluster-name", "research-sandbox-euw1-1-eks", "--region", "eu-west-1", "--output", "json"])
    error_message = "exec is aws eks get-token for the cluster and region, with no --role-arn"
  }
  assert {
    condition     = output.exec.api_version == "client.authentication.k8s.io/v1beta1"
    error_message = "exec uses the v1beta1 client authentication API"
  }
}

run "aws_exec_unchanged" {
  command = plan

  assert {
    condition     = output.exec.command == "aws" && contains(output.exec.args, "get-token")
    error_message = "AWS clusters log in with aws eks get-token"
  }
  assert {
    condition     = output.oidc_issuer_url == null && output.key_vault_id == null && output.node_resource_group == null && output.kubelet_identity_object_id == null
    error_message = "the AKS-only facts are null on AWS"
  }
}

run "azure_finds_cluster" {
  command = plan

  variables {
    cloud  = "azure"
    region = "westeurope"
    state = {
      subscription_id = "00000000-0000-0000-0000-000000000001"
      resource_group  = "rg-phoenix-state"
      storage_account = "acmetfstateweu"
      container       = "research-sandbox"
    }
  }

  override_data {
    target = data.terraform_remote_state.core_platform_azure[0]
    values = {
      outputs = {
        clusters = {
          "1" = {
            cluster_name                       = "research-sandbox-weu-1-aks"
            cluster_endpoint                   = "https://research-sandbox-weu-1.privatelink.westeurope.azmk8s.io:443"
            cluster_certificate_authority_data = "Q0EtREFUQQ=="
            oidc_issuer_url                    = "https://weu.oic.prod-aks.azure.com/t/1/"
            node_resource_group                = "rg-research-sandbox-weu-1-nodes"
            vnet_id                            = "/subscriptions/s/resourceGroups/rg-research-sandbox-weu-network/providers/Microsoft.Network/virtualNetworks/vnet-1"
            node_subnet_ids                    = ["/subscriptions/s/.../subnets/nodes-1"]
            key_vault_id                       = "/subscriptions/s/resourceGroups/rg-research-sandbox-weu-platform/providers/Microsoft.KeyVault/vaults/kv-research-sandbox"
            kubelet_identity_object_id         = "00000000-0000-0000-0000-0000000000dd"
            nap                                = true
          }
        }
      }
    }
  }

  override_data {
    target = data.terraform_remote_state.dns_azure[0]
    values = { outputs = {} }
  }

  assert {
    condition     = output.exec.command == "kubelogin" && output.exec.args == tolist(["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"])
    error_message = "AKS clusters log in with kubelogin, on the runner's azure/login session"
  }
  assert {
    condition     = output.oidc_issuer_url == "https://weu.oic.prod-aks.azure.com/t/1/"
    error_message = "the cluster's OIDC issuer, for workload identity federation"
  }
  assert {
    condition     = output.vpc_id == "/subscriptions/s/resourceGroups/rg-research-sandbox-weu-network/providers/Microsoft.Network/virtualNetworks/vnet-1"
    error_message = "vpc_id is the VNet on Azure"
  }
  assert {
    condition     = output.cluster_name == "research-sandbox-weu-1-aks" && output.key_vault_id != null && output.kubelet_identity_object_id == "00000000-0000-0000-0000-0000000000dd"
    error_message = "the AKS facts come from the same cluster entry"
  }
}

run "azure_cluster_missing_fails_cleanly" {
  command = plan

  variables {
    cloud  = "azure"
    region = "westeurope"
    state = {
      subscription_id = "00000000-0000-0000-0000-000000000001"
      resource_group  = "rg-phoenix-state"
      storage_account = "acmetfstateweu"
      container       = "research-sandbox"
    }
  }

  override_data {
    target = data.terraform_remote_state.core_platform_azure[0]
    values = { outputs = {} }
  }

  override_data {
    target = data.terraform_remote_state.dns_azure[0]
    values = { outputs = {} }
  }

  expect_failures = [terraform_data.validation]
}
