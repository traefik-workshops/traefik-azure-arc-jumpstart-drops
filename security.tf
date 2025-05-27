module "entra_id" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//security/entraid?ref=main"

  users = [ "employee", "customer", "flight-staff", "ticket-agent" ]

  count = var.enableTraefikAirlinesHubGateway || var.enableTraefikHubManagement ? 1 : 0
}

output "entraIDTenantID" {
  sensitive = true
  value     = module.entra_id[0].tenant_id
}

output "entraIDApplicationClientID" {
  sensitive = true
  value     = module.entra_id[0].application_client_id
}

output "entraIDApplicationClientSecret" {
  sensitive = true
  value     = module.entra_id[0].application_client_secret
}

output "entraIDUsers" {
  value = module.entra_id[0].users
}
