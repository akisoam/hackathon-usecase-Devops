    variable "vnet_name" {
      description = "The name of the Virtual Network."
      type        = string
    }

    variable "address_space" {
      description = "The address space of the Virtual Network."
      type        = list(string)
    }

    variable "location" {
      description = "The Azure region where the Virtual Network will be deployed."
      type        = string
    }

    variable "resource_group_name" {
      description = "The name of the resource group where the Virtual Network will be deployed."
      type        = string
    }

    variable "tags" {
      description = "A map of tags to assign to the Virtual Network."
      type        = map(string)
      default     = {}
    }