locals {
  gke_cluster_name = "gke-traefik-demo"
}

provider "google" {
  project = var.googleProjectId
}

module "gke" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/gke?ref=main"

  gke_version               = var.gkeVersion
  cluster_name              = local.gke_cluster_name
  cluster_location          = var.gkeClusterLocation
  cluster_node_machine_type = var.gkeClusterMachineType
  cluster_node_count        = var.gkeClusterNodeCount

  count = var.enableGKE ? 1 : 0
}

resource "null_resource" "arc_gke_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 60

      gcloud container clusters get-credentials ${local.gke_cluster_name} \
        --zone ${var.gkeClusterLocation} \
        --project ${var.googleProjectId}

      kubectl config rename-context "gke_${var.googleProjectId}_${var.gkeClusterLocation}_${local.gke_cluster_name}" "${local.gke_cluster_name}"

      az connectedk8s connect \
        --kube-context "${local.gke_cluster_name}" \
        --name "arc-${local.gke_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enableGKE ? 1 : 0
  depends_on = [ module.gke ]
}

provider "kubernetes" {
  alias                  = "gke"
  host                   = "https://${module.gke.0.host}"
  cluster_ca_certificate = module.gke.0.cluster_ca_certificate
  token                  = module.gke.0.token
}

data "kubernetes_service" "traefik_gke" {
  provider = kubernetes.gke

  metadata {
    name      = "traefik-gke"
    namespace = "traefik"
  }

  count      = var.enableGKE && var.enableTraefik ? 1 : 0
  depends_on = [ azurerm_resource_group_template_deployment.traefik ]
}

output "traefikGKEAddress" {
  value = var.enableGKE && var.enableTraefik ? data.kubernetes_service.traefik_gke.0.status.0.load_balancer.0.ingress.0.ip : ""
}