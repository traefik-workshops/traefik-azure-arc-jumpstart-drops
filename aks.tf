locals {
  aks_cluster_name = "aks-traefik-demo"
}

module "aks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/aks?ref=main"

  resource_group_name  = azurerm_resource_group.traefik_demo.name
  aks_version          = var.aksVersion
  cluster_name         = local.aks_cluster_name
  cluster_location     = var.aksClusterLocation
  cluster_machine_type = var.aksClusterMachineType
  cluster_node_count   = var.aksClusterNodeCount

  count = var.enableAKS ? 1 : 0
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
        --name "arc-${local.aks_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enableAKS ? 1 : 0
  depends_on = [ module.aks ]
}

provider "kubernetes" {
  alias                  = "aks"
  host                   = module.aks.0.host
  client_certificate     = module.aks.0.client_certificate
  client_key             = module.aks.0.client_key
  cluster_ca_certificate = module.aks.0.cluster_ca_certificate
}

data "kubernetes_service" "traefik_aks" {
  provider = kubernetes.aks

  metadata {
    name      = "traefik-aks"
    namespace = "traefik"
  }

  count      = var.enableAKS && var.enableTraefik ? 1 : 0
  depends_on = [ azurerm_resource_group_template_deployment.traefik ]
}

output "traefikAKSAddress" {
  value = var.enableAKS && var.enableTraefik ? data.kubernetes_service.traefik_aks.0.status.0.load_balancer.0.ingress.0.ip : ""
}
