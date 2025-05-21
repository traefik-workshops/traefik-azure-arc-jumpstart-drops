locals {
  traefik = {
    "deployment.replicas": "1",
    "global.azure.enabled": true,
    "ingressClass.enabled": false,
    "ingressRoute.dashboard.enabled": "true",
    "ingressRoute.dashboard.matchRule": "Host(`dashboard.traefik`) || Host(`dashboard.traefik.localhost`)",
    "ports.traefik.expose.default": "true",
    "versionOverride": "v3.3.6"
  }

  certificatesResolvers = var.enable_traefik_airlines_tls ? {
    "certificatesResolvers.traefik-airlines.acme.email": "zaid@traefik.io",
    "certificatesResolvers.traefik-airlines.acme.storage": "/data/acme.json",
    "certificatesResolvers.traefik-airlines.acme.httpChallenge.entryPoint": "web"
  } : {}

  config = merge(local.traefik, local.certificatesResolvers)
}

resource "azurerm_resource_group_template_deployment" "traefik" {
  name                = "traefik"
  resource_group_name = azurerm_resource_group.traefik_demo.name
  deployment_mode     = "Incremental"
  template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "outputs": {},
    "parameters": {},
    "resources": [
        {
            "apiVersion": "2023-05-01",
            "name": "traefik",
            "plan": {
                "name": "traefik-byol",
                "product": "traefik-on-arc",
                "publisher": "containous"
            },
            "properties": {
                "autoUpgradeMinorVersion": "true",
                "configurationProtectedSettings": {},
                "configurationSettings": ${jsonencode(local.config)},
                "extensionType": "TraefikLabs.TraefikProxyOnArc",
                "releaseTrain": "stable",
                "scope": {
                    "cluster": {
                        "releaseNamespace": "traefik"
                    }
                }
            },
            "scope": "Microsoft.Kubernetes/connectedClusters/arc-${each.value}-traefik-demo",
            "type": "Microsoft.KubernetesConfiguration/extensions"
        }
    ]
}
TEMPLATE

  for_each   = var.enable_traefik ? toset(local.clusters) : []
  depends_on = [ null_resource.arc_aks_cluster, null_resource.arc_k3d_cluster ]
}
