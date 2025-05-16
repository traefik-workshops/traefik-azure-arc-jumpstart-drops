locals {
  k3d_cluster_name     = "k3d-${k3d_cluster.traefik_demo[0].name}"
  arc_k3d_cluster_name = "traefik-arc-k3d-demo"
  arc_k3d_cluster_id   = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_k3d_cluster_name}"
}

resource "k3d_cluster" "traefik_demo" {
  name    = "traefik-demo"
  # See https://k3d.io/v5.8.3/usage/configfile/#config-options
  k3d_config = <<EOF
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${local.arc_k3d_cluster_name}
servers: 1
ports:
  - port: 8000:80
    nodeFilters:
      - loadbalancer
  - port: 8443:443
    nodeFilters:
      - loadbalancer
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: "--disable=traefik"
        nodeFilters:
          - "server:*"
EOF

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

  depends_on = [ k3d_cluster.traefik_demo ]

  count = var.enable_k3d ? 1 : 0
}