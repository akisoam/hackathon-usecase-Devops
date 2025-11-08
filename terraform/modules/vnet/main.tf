resource "azurerm_virtual_network" "main" {
      name                = var.vnet_name
      address_space       = var.address_space
      location            = var.location
      resource_group_name = var.resource_group_name
      tags                = var.tags
    }

    output "vnet_id" {
      value = azurerm_virtual_network.main.id
    }

    output "vnet_name" {
      value = azurerm_virtual_network.main.name
    }