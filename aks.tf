locals {
  aks_cluster_name     = "traefik-aks-demo"
  arc_aks_cluster_name = "traefik-arc-aks-demo"
  arc_aks_cluster_id   = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_aks_cluster_name}"
}

module "aks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/aks?ref=main"

  resource_group_name  = azurerm_resource_group.traefik_demo.name
  cluster_location     = azurerm_resource_group.traefik_demo.location
  aks_version          = var.aks_version
  cluster_name         = local.aks_cluster_name
  cluster_machine_type = var.aks_cluster_machine_type
  cluster_node_count   = var.aks_cluster_node_count

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
  depends_on = [ module.aks ]
}

provider "kubernetes" {
  host                   = module.aks.0.host
  client_certificate     = module.aks.0.client_certificate
  client_key             = module.aks.0.client_key
  cluster_ca_certificate = module.aks.0.cluster_ca_certificate
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }

  count = var.enable_aks && var.enable_traefik ? 1 : 0
  depends_on = [ module.aks, azurerm_resource_group_template_deployment.traefik ]
}

output "aksTraefikIp" {
  value = var.enable_aks && var.enable_traefik ? data.kubernetes_service.traefik.0.status.0.load_balancer.0.ingress.0.ip : ""
}
