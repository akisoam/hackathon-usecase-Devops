    # modules/subnet/main.tf
    resource "azurerm_subnet" "private" {
      for_each             = var.subnets
      name                 = each.value.name
      resource_group_name  = var.resource_group_name
      virtual_network_name = var.vnet_name
      address_prefixes     = each.value.address_prefixes
      service_endpoints    = lookup(each.value, "service_endpoints", null)
      delegations          = lookup(each.value, "delegations", null)
    }


resource "azurerm_subnet" "public" {
      for_each             = var.subnets
      name                 = each.value.name
      resource_group_name  = var.resource_group_name
      virtual_network_name = var.vnet_name
      address_prefixes     = each.value.address_prefixes
      service_endpoints    = lookup(each.value, "service_endpoints", null)
      delegations          = lookup(each.value, "delegations", null)
    }
