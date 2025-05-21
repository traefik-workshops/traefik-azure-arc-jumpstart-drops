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

provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks.0.cluster_endpoint
  cluster_ca_certificate = module.eks.0.cluster_ca_certificate
  token                  = module.eks.0.token
}

data "kubernetes_service" "traefik_eks" {
  provider = kubernetes.eks

  metadata {
    name      = "traefik-eks"
    namespace = "traefik"
  }

  count      = var.enableEKS && var.enableTraefik ? 1 : 0
  depends_on = [ azurerm_resource_group_template_deployment.traefik ]
}

output "traefikEKSAddress" {
  value = var.enableEKS && var.enableTraefik ? data.kubernetes_service.traefik_eks.0.status.0.load_balancer.0.ingress.0.hostname : ""
}
