locals {
  arc_cluster_prefix = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters"

  k3d = var.enableK3D ? ["k3d"] : []
  aks = var.enableAKS ? ["aks"] : []
  eks = var.enableEKS ? ["eks"] : []
  gke = var.enableGKE ? ["gke"] : []
  clusters = toset(concat(local.k3d, local.aks, local.eks, local.gke))
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.azureSubscriptionId
}

resource "azurerm_resource_group" "traefik_demo" {
  name     = "traefik-demo"
  location = var.azureLocation
}

resource "azurerm_arc_kubernetes_cluster_extension" "flux" {
  name           = "flux"
  cluster_id     = "${local.arc_cluster_prefix}/arc-${each.value}-traefik-demo"
  extension_type = "microsoft.flux"

  identity {
    type = "SystemAssigned"
  }

  for_each = var.enableTraefikAirlines ? local.clusters : []
  depends_on = [null_resource.arc_clusters]
}

resource "azurerm_arc_kubernetes_flux_configuration" "traefik_airlines" {
  name       = "traefik-airline-${each.value}"
  cluster_id = "${local.arc_cluster_prefix}/arc-${each.value}-traefik-demo"
  namespace  = "traefik-airlines"

  git_repository {
    url = "https://github.com/traefik-workshops/traefik-airlines.git"
    reference_type = "tag"
    reference_value = "v0.0.6"
  }

  kustomizations {
    name = "traefik-airlines"
  }

  for_each   = var.enableTraefikAirlines ? local.clusters : []
  depends_on = [ azurerm_arc_kubernetes_cluster_extension.flux, azurerm_resource_group_template_deployment.traefik ]
}