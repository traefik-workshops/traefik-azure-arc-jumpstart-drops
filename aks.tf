# provider "kubernetes" {
#   host                   = module.aks.0.host
#   client_certificate     = module.aks.0.client_certificate
#   client_key             = module.aks.0.client_key
#   cluster_ca_certificate = module.aks.0.cluster_ca_certificate
# }

# data "kubernetes_service" "traefik" {
#   metadata {
#     name      = "traefik"
#     namespace = "traefik"
#   }

#   count = var.enable_aks && var.enable_traefik ? 1 : 0
#   depends_on = [ module.aks, azurerm_resource_group_template_deployment.traefik ]
# }

# output "aksTraefikIp" {
#   value = var.enable_aks && var.enable_traefik ? data.kubernetes_service.traefik.0.status.0.load_balancer.0.ingress.0.ip : ""
# }
