output "resource_group_name" {
  description = "Azure resource group name"
  value = azurerm_resource_group.traefik_demo.name
}

output "host" {
  description = "K3D cluster host"
  sensitive = false
  value = k3d_cluster.traefik_demo.host
}

output "client_certificate" {
  description = "K3D cluster client certificate"
  sensitive = true
  value = base64decode(k3d_cluster.traefik_demo.client_certificate)
}

output "client_key" {
  description = "K3D cluster client key"
  sensitive = true
  value = base64decode(k3d_cluster.traefik_demo.client_key)
}

output "cluster_ca_certificate" {
  description = "K3D cluster CA certificate"
  sensitive = true
  value = base64decode(k3d_cluster.traefik_demo.cluster_ca_certificate)
}