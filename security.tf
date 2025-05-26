module "entra_id" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//security/entraid?ref=main"

  users = [ "employee", "customer", "flight-staff", "ticket-agent" ]

  count = var.enableTraefikAirlinesOauth2 ? 1 : 0
}