provider "aws" {
  region = var.eks_cluster_location
}

module "eks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/eks?ref=main"

  cluster_name              = local.eks_cluster_name
  cluster_location          = var.eks_cluster_location
  cluster_node_machine_type = var.eks_cluster_machine_type
  cluster_node_count        = var.eks_cluster_node_count

  count = var.enable_eks ? 1 : 0
}

resource "null_resource" "arc_eks_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      aws eks --region "${var.eks_cluster_location}" update-kubeconfig \
        --name "${local.eks_cluster_name}" \
        --alias "${local.eks_cluster_name}"
      
      az connectedk8s connect \
        --kube-context ${local.eks_cluster_name} \
        --name "arc-${local.eks_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  count      = var.enable_eks ? 1 : 0
  depends_on = [ module.eks ]
}
