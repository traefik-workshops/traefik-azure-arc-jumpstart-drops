locals {
  k3d_cluster_name = "k3d-traefik-demo"
}

module "k3d" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/k3d?ref=main"

  cluster_name = "traefik-demo"

  count = var.enableK3D ? 1 : 0
}

resource "null_resource" "arc_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --kube-context ${local.k3d_cluster_name} \
        --name "arc-${local.k3d_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enableK3D ? 1 : 0
  depends_on = [ module.k3d ]
}

provider "kubernetes" {
  alias                  = "k3d"
  host                   = module.k3d.0.host
  client_certificate     = module.k3d.0.client_certificate
  client_key             = module.k3d.0.client_key
  cluster_ca_certificate = module.k3d.0.cluster_ca_certificate
}
