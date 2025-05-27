module "entra_id" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//security/entraid?ref=main"

  users = [ "employee", "customer", "flight-staff", "ticket-agent" ]

  count = var.enableTraefikHubGateway || var.enableTraefikHubManagement ? 1 : 0
}

output "entraIDTenantID" {
  sensitive = true
  value     = var.enableTraefikHubGateway || var.enableTraefikHubManagement ? module.entra_id[0].tenant_id : null
}

output "entraIDApplicationClientID" {
  sensitive = true
  value     = var.enableTraefikHubGateway || var.enableTraefikHubManagement ? module.entra_id[0].application_client_id : null
}

output "entraIDApplicationClientSecret" {
  sensitive = true
  value     = var.enableTraefikHubGateway || var.enableTraefikHubManagement ? module.entra_id[0].application_client_secret : null
}

output "entraIDUsers" {
  value = var.enableTraefikHubGateway || var.enableTraefikHubManagement ? module.entra_id[0].users : null
}
