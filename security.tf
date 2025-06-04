locals {
  aks_redirect_uri = var.enableAKS ? ["https://portal.airlines.traefik.${local.traefik_ips["aks"]}.sslip.io/callback"] : []
  eks_redirect_uri = var.enableEKS ? ["https://portal.airlines.traefik.${local.traefik_ips["eks"]}.sslip.io/callback"] : []
  gke_redirect_uri = var.enableGKE ? ["https://portal.airlines.traefik.${local.traefik_ips["gke"]}.sslip.io/callback"] : []
  redirect_uris = concat(local.aks_redirect_uri, local.eks_redirect_uri, local.gke_redirect_uri)
}

module "entra_id" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//security/entraid?ref=main"

  users = [ "employee", "customer", "flight-staff", "ticket-agent" ]
  redirect_uris = local.redirect_uris

  count = local.enableHub ? 1 : 0
  depends_on = [ null_resource.traefik_ips ]
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
