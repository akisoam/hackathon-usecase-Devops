    # modules/subnet/variables.tf
    variable "resource_group_name" {
      description = "The name of the resource group where the subnets will be deployed."
      type        = string
    }

    variable "vnet_name" {
      description = "The name of the Virtual Network where the subnets will be created."
      type        = string
    }

    variable "subnets" {
      description = "A map of subnet configurations."
      type = map(object({
        name             = string
        address_prefixes = list(string)
        service_endpoints = optional(list(string))
        delegations       = optional(list(object({
          name          = string
          service_name  = string
          actions       = optional(list(string))
        })))
      }))
    }