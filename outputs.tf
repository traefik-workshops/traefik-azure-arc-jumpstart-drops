output "resource_group_name" {
  description = "Azure resource group name"
  value = azurerm_resource_group.traefik_demo.name
}

output "k3d_cluster_name" {
  description = "K3D cluster name"
  value = "k3d-${k3d_cluster.traefik_demo[0].name}"
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value = azurerm_kubernetes_cluster.traefik_demo[0].name
}
