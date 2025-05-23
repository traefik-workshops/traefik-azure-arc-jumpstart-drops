locals {
  aks_cluster_name     = "traefik-aks-demo"
  arc_aks_cluster_name = "traefik-arc-aks-demo"
  arc_aks_cluster_id   = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_aks_cluster_name}"
}

resource "azurerm_kubernetes_cluster" "traefik_demo" {
  name                = local.aks_cluster_name
  location            = azurerm_resource_group.traefik_demo.location
  kubernetes_version  = var.aks_version
  resource_group_name = azurerm_resource_group.traefik_demo.name
  dns_prefix          = replace(azurerm_resource_group.traefik_demo.name, "_", "-")

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.aks_cluster_machine_type

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  count = var.enable_aks ? 1 : 0
}

resource "azurerm_kubernetes_cluster_node_pool" "traefik_demo" {
  name                  = substr(replace(azurerm_resource_group.traefik_demo.name, "-", ""), 0, 12)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.traefik_demo[0].id
  vm_size               = var.aks_cluster_machine_type
  node_count            = var.aks_cluster_node_count

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  count = var.enable_aks ? 1 : 0
}

resource "null_resource" "arc_aks_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials \
        --overwrite-existing \
        --resource-group ${azurerm_resource_group.traefik_demo.name} \
        --name ${local.aks_cluster_name}
      
      az connectedk8s connect \
        --kube-context ${local.aks_cluster_name} \
        --name ${local.arc_aks_cluster_name} \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count = var.enable_aks ? 1 : 0
  depends_on = [ azurerm_kubernetes_cluster.traefik_demo, azurerm_kubernetes_cluster_node_pool.traefik_demo ]
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.traefik_demo[0].kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.traefik_demo[0].kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.traefik_demo[0].kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.traefik_demo[0].kube_config[0].cluster_ca_certificate)
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }

  count = var.enable_aks ? 1 : 0
  depends_on = [ azurerm_resource_group_template_deployment.traefik ]
}

output "aksTraefikIp" {
  value = var.enable_aks ? data.kubernetes_service.traefik.0.status.0.load_balancer.0.ingress.0.ip : ""
}
