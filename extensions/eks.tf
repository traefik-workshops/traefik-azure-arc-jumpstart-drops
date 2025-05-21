locals {
  eks_cluster_name = "eks-traefik-demo"
}

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

  count = var.enableEKS ? 1 : 0
}

resource "null_resource" "arc_eks_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      aws eks --region "${var.eksClusterLocation}" update-kubeconfig \
        --name "${local.eks_cluster_name}" \
        --alias "${local.eks_cluster_name}"
      
      az connectedk8s connect \
        --kube-context ${local.eks_cluster_name} \
        --name "arc-${local.eks_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enableEKS ? 1 : 0
  depends_on = [ module.eks ]
}
