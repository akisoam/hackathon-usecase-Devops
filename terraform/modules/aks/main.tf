resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-aks"

  default_node_pool {
    name       = "agentpool"
    node_count = var.node_count
    vm_size    = var.node_vm_size
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    network_plugin = "azure"
  }
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

# admin kubeconfig (base64-encoded raw kubeconfig)
output "kube_admin_config_raw" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}
