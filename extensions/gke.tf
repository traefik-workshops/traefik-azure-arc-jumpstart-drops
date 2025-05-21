provider "google" {
  project = var.google_project_id
}

module "gke" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/gke?ref=main"

  cluster_name              = local.gke_cluster_name
  cluster_location          = var.gke_cluster_location
  cluster_node_machine_type = var.gke_cluster_machine_type
  cluster_node_count        = var.gke_cluster_node_count

  count = var.enable_gke ? 1 : 0
}

resource "null_resource" "arc_gke_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${local.gke_cluster_name} \
        --zone ${var.gke_cluster_location} \
        --project ${var.google_project_id}
      
      az connectedk8s connect \
        --kube-context gke_${var.google_project_id}_${var.gke_cluster_location}_${local.gke_cluster_name} \
        --name "arc-${local.gke_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enable_gke ? 1 : 0
  depends_on = [ module.gke ]
}