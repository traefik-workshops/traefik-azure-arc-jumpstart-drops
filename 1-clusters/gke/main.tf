provider "google" {
  project = var.googleProjectId
}

module "gke" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/gke?ref=main"

  gke_version          = var.gkeVersion
  cluster_name         = "gke-traefik-demo"
  cluster_location     = var.gkeClusterLocation
  cluster_machine_type = var.gkeClusterMachineType
  cluster_node_count   = var.gkeClusterNodeCount
}
