locals {
  k3d = var.enable_k3d ? ["k3d"] : []
  aks = var.enable_aks ? ["aks"] : []
  clusters = concat(local.k3d, local.aks)
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "traefik_demo" {
  name     = "traefik-demo"
  location = var.azure_location
}

resource "azurerm_arc_kubernetes_cluster_extension" "flux" {
  name           = "flux"
  cluster_id     = each.value == "aks" ? local.arc_aks_cluster_id : local.arc_k3d_cluster_id
  extension_type = "microsoft.flux"

  identity {
    type = "SystemAssigned"
  }

  for_each = var.enable_traefik_airlines ? toset(local.clusters) : []
  depends_on = [ null_resource.arc_aks_cluster, null_resource.arc_k3d_cluster ]
}

resource "azurerm_arc_kubernetes_flux_configuration" "traefik_airlines" {
  name       = "traefik-airlines"
  cluster_id = each.value == "aks" ? local.arc_aks_cluster_id : local.arc_k3d_cluster_id
  namespace  = "traefik-airlines"

  git_repository {
    url = "https://github.com/traefik-workshops/traefik-airlines.git"
    reference_type = "tag"
    reference_value = "v0.0.1"
  }

  kustomizations {
    name = "traefik-airlines"
  }

  for_each   = var.enable_traefik_airlines ? toset(local.clusters) : []
  depends_on = [ azurerm_arc_kubernetes_cluster_extension.flux, azurerm_resource_group_template_deployment.traefik ]
}