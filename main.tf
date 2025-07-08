terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.34.0"
    }
  }
}

provider "azurerm" {
  features {}
subscription_id = "f569e8dc-40e1-4d01-9de4-e79fd05beaa6"
}

# resource "azurerm_resource_group" "aks" {
#   name     = "dhirurg"
#   location = "South India"
# }

resource "azurerm_kubernetes_cluster" "newaks" {
  name                = "example-aks1"
  location            = "West US"
  resource_group_name = "dhirurg"
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "standard_a2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.newaks.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.newaks.kube_config_raw

  sensitive = true
}


# Attach existing ACR to AKS
data "azurerm_container_registry" "existing" {
  name                = "dhirendradockerrg"                  # 👈 your ACR name
  resource_group_name = "dhirurg"                     # 👈 your ACR RG
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.newaks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.existing.id
}