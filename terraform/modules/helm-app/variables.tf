variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "chart" {
  type = string
}

variable "values" {
  type = any
  default = {}
}

variable "kubeconfig" {
  description = "Raw kubeconfig content (base64 or plain)"
  type        = string
}
