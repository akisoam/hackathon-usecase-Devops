variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "hackathon"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "AKS node count"
  type        = number
  default     = 2
}

# Network variables
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet prefix for AKS"
  type        = string
  default     = "10.0.1.0/24"
}
