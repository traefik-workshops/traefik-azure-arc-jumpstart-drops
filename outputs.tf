output "resourceGroupName" {
  description = "Azure resource group name"
  value = azurerm_resource_group.traefik_demo.name
}

output "k3dClusterName" {
  description = "k3d cluster name"
  value = local.k3d_cluster_name
}

output "aksClusterName" {
  description = "AKS cluster name"
  value = local.aks_cluster_name
}
