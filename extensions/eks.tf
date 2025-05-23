provider "aws" {
  region = var.eksClusterLocation
}

module "eks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/eks?ref=main"

  eks_version               = var.eksVersion
  cluster_name              = local.eks_cluster_name
  cluster_location          = var.eksClusterLocation
  cluster_node_machine_type = var.eksClusterMachineType
  cluster_node_count        = var.eksClusterNodeCount

  count      = var.enableEKS ? 1 : 0
  depends_on = [null_resource.arc_eks_cluster_destroy]
}
