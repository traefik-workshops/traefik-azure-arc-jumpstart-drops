locals {
  aks_cluster_name = "aks-traefik-demo"
  k3d_cluster_name = "k3d-traefik-demo"
  eks_cluster_name = "eks-traefik-demo"
  gke_cluster_name = "gke-traefik-demo"
}

module "aks" {
  source = "git::https://github.com/traefik-workshops/terraform-demo-modules.git//clusters/aks?ref=main"

  resource_group_name  = azurerm_resource_group.traefik_demo.name
  aks_version          = var.aksVersion
  cluster_name         = local.aks_cluster_name
  cluster_location     = var.aksClusterLocation
  cluster_machine_type = var.aksClusterMachineType
  cluster_node_count   = var.aksClusterNodeCount

  count = var.enableAKS ? 1 : 0
}

resource "null_resource" "arc_aks_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials \
        --overwrite-existing \
        --resource-group ${azurerm_resource_group.traefik_demo.name} \
        --name ${local.aks_cluster_name}
      
      az connectedk8s connect \
        --kube-context ${local.aks_cluster_name} \
        --name "arc-${local.aks_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      az connectedk8s delete --force --yes \
        --name "arc-aks-traefik-demo" \
        --resource-group "traefik-demo"

      kubectl config delete-context "aks-traefik-demo" 2>/dev/null || true
    EOT
  }

  count      = var.enableAKS ? 1 : 0
  depends_on = [ module.aks ]
}

provider "kubernetes" {
  alias = "aks"

  config_path    = "~/.kube/config"
  config_context = local.aks_cluster_name
}

resource "null_resource" "arc_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --kube-context ${local.k3d_cluster_name} \
        --name "arc-${local.k3d_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      az connectedk8s delete --force --yes \
        --name "arc-k3d-traefik-demo" \
        --resource-group "traefik-demo"

      kubectl config delete-context "k3d-traefik-demo" 2>/dev/null || true
    EOT
  }

  count = var.enableK3D ? 1 : 0
}

provider "kubernetes" {
  alias = "k3d"

  config_path    = "~/.kube/config"
  config_context = local.k3d_cluster_name
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

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      az connectedk8s delete --force --yes \
        --name "arc-eks-traefik-demo" \
        --resource-group "traefik-demo"

      kubectl config delete-context "eks-traefik-demo" 2>/dev/null || true
    EOT
  }

  count = var.enableEKS ? 1 : 0
}



provider "kubernetes" {
  alias = "eks"

  config_path    = "~/.kube/config"
  config_context = local.eks_cluster_name
}

resource "null_resource" "arc_gke_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${local.gke_cluster_name} \
        --zone ${var.gkeClusterLocation} \
        --project ${var.googleProjectId}

      kubectl config delete-context "${local.gke_cluster_name}" 2>/dev/null || true
      kubectl config rename-context "gke_${var.googleProjectId}_${var.gkeClusterLocation}_${local.gke_cluster_name}" "${local.gke_cluster_name}"

      az connectedk8s connect \
        --kube-context "${local.gke_cluster_name}" \
        --name "arc-${local.gke_cluster_name}" \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      az connectedk8s delete --force --yes \
        --name "arc-gke-traefik-demo" \
        --resource-group "traefik-demo"

      kubectl config delete-context "gke-traefik-demo" 2>/dev/null || true
    EOT
  }

  count = var.enableGKE ? 1 : 0
}

provider "kubernetes" {
  alias = "gke"

  config_path    = "~/.kube/config"
  # config_context = local.gke_cluster_name
  config_context = "gke_"
}

resource "null_resource" "arc_clusters" {
  provisioner "local-exec" {
    command = <<EOT
      echo "${local.aks_cluster_name}"
      echo "${local.k3d_cluster_name}"
      echo "${local.eks_cluster_name}"
      echo "${local.gke_cluster_name}"
    EOT
  }

  depends_on = [ null_resource.arc_aks_cluster, null_resource.arc_k3d_cluster, null_resource.arc_eks_cluster, null_resource.arc_gke_cluster ]
}