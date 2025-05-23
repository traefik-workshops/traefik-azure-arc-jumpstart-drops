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

  count      = var.enableGKE ? 1 : 0
  depends_on = [null_resource.arc_gke_cluster_destroy]
}
