locals {
  arc_cluster_prefix = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters"

  k3d_cluster_name = "k3d-traefik-demo"
  aks_cluster_name = "aks-traefik-demo"
  eks_cluster_name = "eks-traefik-demo"
  gke_cluster_name = "gke-traefik-demo"
}

module "k3d" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/k3d?ref=main"

  cluster_name = "traefik-demo"

  count = var.enable_k3d ? 1 : 0
}

resource "null_resource" "arc_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --kube-context ${local.k3d_cluster_name} \
        --name "arc-${local.k3d_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enable_k3d ? 1 : 0
  depends_on = [ module.k3d ]
}

module "aks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/aks?ref=main"

  resource_group_name  = azurerm_resource_group.traefik_demo.name
  aks_version          = var.aks_version
  cluster_name         = local.aks_cluster_name
  cluster_location     = var.aks_cluster_location
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
        --name "arc-${local.aks_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enable_aks ? 1 : 0
  depends_on = [ module.aks ]
}
