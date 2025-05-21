output "resourceGroupName" {
  description = "Azure resource group name"
  value = azurerm_resource_group.traefik_demo.name
}

output "k3dClusterName" {
  description = "k3d cluster name"
  value = var.enableK3D ? local.k3d_cluster_name : ""
}

output "aksClusterName" {
  description = "AKS cluster name"
  value = var.enableAKS ? local.aks_cluster_name : ""
}

output "eksClusterName" {
  description = "EKS cluster name"
  value = var.enableEKS ? local.eks_cluster_name : ""
}

output "gkeClusterName" {
  description = "GKE cluster name"
  value = var.enableGKE ? local.gke_cluster_name : ""
}
