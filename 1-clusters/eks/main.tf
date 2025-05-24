provider "aws" {
  region = var.eksClusterLocation
}

module "eks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/eks?ref=main"

  eks_version          = var.eksVersion
  cluster_name         = "eks-traefik-demo"
  cluster_location     = var.eksClusterLocation
  cluster_machine_type = var.eksClusterMachineType
  cluster_node_count   = var.eksClusterNodeCount
}
