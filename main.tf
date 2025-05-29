locals {
  arc_cluster_prefix = "/subscriptions/${var.azureSubscriptionId}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters"

  aks = var.enableAKS ? ["aks"] : []
  k3d = var.enableK3D ? ["k3d"] : []
  eks = var.enableEKS ? ["eks"] : []
  gke = var.enableGKE ? ["gke"] : []
  clusters = toset(concat(local.aks, local.k3d, local.eks, local.gke))

  kustomizations_path = var.enableTraefikHubGateway ? "gateway/security/jwt/entraID" : var.enableTraefikHubManagement ? "management" : "proxy/base"

  traefikAirlineVersion = "v0.0.30"
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
  name       = "traefik-airlines-${each.value}"
  cluster_id = "${local.arc_cluster_prefix}/arc-${each.value}-traefik-demo"
  namespace  = "traefik-airlines"

  git_repository {
    url = "https://github.com/traefik-workshops/traefik-airlines.git"
    reference_type = "tag"
    reference_value = local.traefikAirlineVersion
  }

  kustomizations {
    name                       = "traefik-airlines"
    path                       = local.kustomizations_path
    depends_on                 = []
    garbage_collection_enabled = false
    recreating_enabled         = false
    retry_interval_in_seconds  = 600
    sync_interval_in_seconds   = 600
    timeout_in_seconds         = 600
  }

  for_each   = var.enableTraefikAirlines ? local.clusters : []
  depends_on = [ azurerm_arc_kubernetes_cluster_extension.flux, azurerm_resource_group_template_deployment.traefik ]
}

// Clean up Traefik Airlines resources on deletion
resource "null_resource" "azurerm_arc_kubernetes_flux_configuration_traefik_airlines_destroy" {
  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      kubectl delete namespace traefik-airlines \
        --context "${each.key}-traefik-demo" \
        --ignore-not-found=true
    EOT
  }

  for_each   = var.enableTraefikAirlines ? toset(local.clusters) : []
  depends_on = [ azurerm_arc_kubernetes_flux_configuration.traefik_airlines ]
}
