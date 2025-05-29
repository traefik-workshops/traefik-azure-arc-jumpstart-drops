module "entra_id" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//security/entraid?ref=main"

  users = [ "employee", "customer", "flight-staff", "ticket-agent" ]
  # redirect_uris = [ "https://portal.traefik-airlines.*.sslip.io/callback" ]
  redirect_uris = [ "https://portal.traefik-airlines.sslip.io/callback" ]

  count = local.enableHub ? 1 : 0
}

output "entraIDTenantID" {
  sensitive = true
  value     = local.enableHub ? module.entra_id[0].tenant_id : null
}

output "entraIDApplicationClientID" {
  sensitive = true
  value     = local.enableHub ? module.entra_id[0].application_client_id : null
}

output "entraIDApplicationClientSecret" {
  sensitive = true
  value     = local.enableHub ? module.entra_id[0].application_client_secret : null
}

output "entraIDUsers" {
  value = local.enableHub ? module.entra_id[0].users : null
}
