locals {
  k3d_cluster_name     = "k3d-traefik-demo"
  arc_k3d_cluster_name = "traefik-arc-k3d-demo"
  arc_k3d_cluster_id   = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_k3d_cluster_name}"
}

module "k3d" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/k3d?ref=main"

  cluster_name = "traefik-demo"

  count = var.enable_k3d ? 1 : 0
}

resource "null_resource" "arc_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --kube-context ${local.k3d_cluster_name} \
        --name ${local.arc_k3d_cluster_name} \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  depends_on = [ module.k3d ]

  count = var.enable_k3d ? 1 : 0
}