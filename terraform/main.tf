terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id = "0b889ca3-c111-47fc-b0ed-88a37593b8fa"
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}
module "vnet_deployment" {
      source = "./modules/vnet"

      vnet_name           = "hackathon-vnet-akash"
      address_space       = ["10.0.0.0/16"]
      location            = "East US"
      resource_group_name = "hackathon-0811-AkashSoam"
      tags = {
        environment = "hackathon"
      }
    }

resource "azurerm_subnet" "example_subnet" {
  name                 = "public-subnet"
  resource_group_name = "hackathon-0811-AkashSoam"
  virtual_network_name = module.vnet_deployment.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "example_subnet2" {
  name                 = "private-subnet"
  resource_group_name = "hackathon-0811-AkashSoam"
  virtual_network_name = module.vnet_deployment.vnet_name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create the Azure Container Registry
resource "azurerm_container_registry" "my_acr" {
  name                = "acrakashHackathon"
  resource_group_name = "hackathon-0811-AkashSoam"
  location            = "East US"
  sku                 = "Basic"
  admin_enabled       = true
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "hackathon-aks-akash"
  location            = "East US"
  resource_group_name = "hackathon-0811-AkashSoam"
  dns_prefix          = "hackathon-aks"

  default_node_pool {
    name            = "agentpool"
    node_count      = 2
    vm_size         = "Standard_DS2_v2"
    vnet_subnet_id  = azurerm_subnet.example_subnet.id
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  tags = {
    environment = "hackathon"
  }
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.my_acr.id
  skip_service_principal_aad_check = true
}

# Create Kubernetes namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "default"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Deploy Patient Service
resource "kubernetes_deployment" "patient_service" {
  metadata {
    name      = "patient-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "patient-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "patient-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "patient-service"
        }
      }

      spec {
        container {
          name  = "patient-service"
          image = "${azurerm_container_registry.my_acr.login_server}/patient-service:latest"

          port {
            container_port = 3000
          }

          env {
            name  = "PORT"
            value = "3000"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.aks_acr_pull]
}

resource "kubernetes_service" "patient_service" {
  metadata {
    name      = "patient-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "patient-service"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "patient-service"
    }

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# Deploy Application Service
resource "kubernetes_deployment" "application_service" {
  metadata {
    name      = "application-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "application-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "application-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "application-service"
        }
      }

      spec {
        container {
          name  = "application-service"
          image = "${azurerm_container_registry.my_acr.login_server}/application-service:latest"

          port {
            container_port = 3001
          }

          env {
            name  = "PORT"
            value = "3001"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.aks_acr_pull]
}

resource "kubernetes_service" "application_service" {
  metadata {
    name      = "application-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "application-service"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "application-service"
    }

    port {
      port        = 80
      target_port = 3001
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# Deploy Order Service
resource "kubernetes_deployment" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "order-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "order-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-service"
        }
      }

      spec {
        container {
          name  = "order-service"
          image = "${azurerm_container_registry.my_acr.login_server}/order-service:latest"

          port {
            container_port = 8080
          }

          env {
            name  = "SERVER_PORT"
            value = "8080"
          }

          env {
            name  = "SPRING_APPLICATION_NAME"
            value = "order-service"
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "1000m"
            }
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.aks_acr_pull]
}

resource "kubernetes_service" "order_service" {
  metadata {
    name      = "order-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "order-service"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "order-service"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# Deploy Ingress
resource "kubernetes_ingress_v1" "services_ingress" {
  metadata {
    name      = "services-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "azure/application-gateway"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/patients"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.patient_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/appointments"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.application_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/orders"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.order_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.patient_service,
    kubernetes_service.application_service,
    kubernetes_service.order_service
  ]
}

# Outputs
output "acr_login_server" {
  value = azurerm_container_registry.my_acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.my_acr.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.my_acr.admin_password
  sensitive = true
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "patient_service_endpoint" {
  value = "http://${kubernetes_service.patient_service.metadata[0].name}.${kubernetes_namespace.app_namespace.metadata[0].name}.svc.cluster.local"
}

output "application_service_endpoint" {
  value = "http://${kubernetes_service.application_service.metadata[0].name}.${kubernetes_namespace.app_namespace.metadata[0].name}.svc.cluster.local"
}

output "order_service_endpoint" {
  value = "http://${kubernetes_service.order_service.metadata[0].name}.${kubernetes_namespace.app_namespace.metadata[0].name}.svc.cluster.local"
}