locals {
  arc_cluster_name = "traefik-demo"
  arc_cluster_id   = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${azurerm_resource_group.traefik_demo.name}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_cluster_name}"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "traefik_demo" {
  name     = "traefik-demo"
  location = var.azure_location
}

# resource "azurerm_arc_kubernetes_cluster" "traefik_demo" {
#   name                         = "traefik-demo"
#   resource_group_name          = azurerm_resource_group.traefik_demo.name
#   location                     = var.azure_location
#   agent_public_key_certificate = output.client_certificate

#   identity {
#     type = "SystemAssigned"
#   }
# }

resource "null_resource" "arc_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --name ${local.arc_cluster_name} \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }

  depends_on = [ k3d_cluster.traefik_demo ]
}

resource "azurerm_arc_kubernetes_cluster_extension" "flux" {
  name           = "flux"
  cluster_id     = local.arc_cluster_id
  extension_type = "microsoft.flux"

  identity {
    type = "SystemAssigned"
  }

  depends_on = [ null_resource.arc_cluster ]
}

resource "azurerm_arc_kubernetes_flux_configuration" "traefik_airlines" {
  name                  = "traefik-airlines"
  cluster_id            = local.arc_cluster_id
  namespace             = "traefik-airlines"
  git_repository {
    url = "https://github.com/traefik-workshops/traefik-airlines.git"
    reference_type = "branch"
    reference_value = "main"
  }

  kustomizations {
    name = "traefik-airlines"
    
  }

  depends_on = [ azurerm_arc_kubernetes_cluster_extension.flux ]
}