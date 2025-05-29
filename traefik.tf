locals {
  enableHub = var.enableTraefikHubGateway || var.enableTraefikHubManagement

  traefik = {
    "deployment.replicas": "1",
    "global.azure.enabled": "true",
    "ingressClass.enabled": "true",
    "kubernetesCRD.enabled": "true",
    "providers.kubernetesCRD.allowCrossNamespace": "true",
    "ingressRoute.dashboard.enabled": "true",
    "ports.traefik.expose.default": "true",
    "rbac.enabled": "true",
    "hub.apimanagement.enabled": var.enableTraefikHubManagement ? "true" : "false",
    "hub.redis.endpoints": var.enableTraefikHubManagement ? "traefik-redis-master.traefik.svc:6379" : "",
    "hub.redis.password": var.enableTraefikHubManagement ? "topsecretpassword" : "",
    "versionOverride": local.enableHub ? "v3.16.1" : "v3.4.0"
  }

  certificatesResolvers = var.enableTraefikAirlinesTLS ? {
    "certificatesResolvers.traefik-airlines.acme.email": "zaid@traefik.io",
    "certificatesResolvers.traefik-airlines.acme.storage": "/data/acme.json",
    "certificatesResolvers.traefik-airlines.acme.httpChallenge.entryPoint": "web"
  } : {}

  config = merge(local.traefik, local.certificatesResolvers)

  clusterSettings = {
    "aks" = {
      "hub.token": "${local.enableHub ? var.traefikHubAKSLicenseKey : ""}",
      "ingressRoute.dashboard.matchRule": "Host(`dashboard.traefik.aks`)"
    }
    "k3d" = {
      "hub.token": "${local.enableHub ? var.traefikHubK3DLicenseKey : ""}",
      "ingressRoute.dashboard.matchRule": "Host(`dashboard.traefik.localhost`)"
    }
    "eks" = {
      "hub.token": "${local.enableHub ? var.traefikHubEKSLicenseKey : ""}",
      "ingressRoute.dashboard.matchRule": "Host(`dashboard.traefik.eks`)"
      "service.annotations.service\\.beta\\.kubernetes\\.io\\/aws-load-balancer-type" = "nlb"
    }
    "gke" = {
      "hub.token": "${local.enableHub ? var.traefikHubGKELicenseKey : ""}",
      "ingressRoute.dashboard.matchRule": "Host(`dashboard.traefik.gke`)"
    }
  }

  traefik_ips = {
    aks = var.enableAKS ? trimspace(data.local_file.traefik_ip["aks"].content) : ""
    eks = var.enableEKS ? trimspace(data.local_file.traefik_ip["eks"].content) : ""
    gke = var.enableGKE ? trimspace(data.local_file.traefik_ip["gke"].content) : ""
  }
}

resource "azurerm_resource_group_template_deployment" "traefik" {
  name                = "traefik-${each.key}"
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
            "name": "traefik-${each.key}",
            "plan": {
                "name": "traefik-byol",
                "product": "traefik-on-arc",
                "publisher": "containous"
            },
            "properties": {
                "autoUpgradeMinorVersion": "true",
                "configurationProtectedSettings": {},
                "configurationSettings": ${jsonencode(merge(local.config, local.clusterSettings[each.key]))},
                "extensionType": "TraefikLabs.TraefikProxyOnArc",
                "releaseTrain": "stable",
                "scope": {
                    "cluster": {
                        "releaseNamespace": "traefik"
                    }
                }
            },
            "scope": "Microsoft.Kubernetes/connectedClusters/arc-${each.key}-traefik-demo",
            "type": "Microsoft.KubernetesConfiguration/extensions"
        }
    ]
}
TEMPLATE

  for_each   = var.enableTraefik ? toset(local.clusters) : []
  depends_on = [null_resource.arc_clusters]
}

// Needed because resource destroy is flaky and those resources stand up LBs that are not tracked by the state
resource "null_resource" "azurerm_resource_group_template_deployment_traefik_destroy" {
  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      az k8s-extension delete --yes \
        --name "traefik-${each.key}" \
        --cluster-name "arc-${each.key}-traefik-demo" \
        --resource-group "traefik-demo" \
        --cluster-type connectedClusters

      kubectl delete namespace traefik --context "${each.key}-traefik-demo"
    EOT
  }

  for_each   = var.enableTraefik ? toset(local.clusters) : []
  depends_on = [ azurerm_resource_group_template_deployment.traefik ]
}

resource "null_resource" "traefik_ips" {
  for_each = var.enableTraefik ? toset(local.clusters) : []

  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
set -e

context="${each.key}"
namespace="traefik"
service_name="traefik-${each.key}"
ip_file="traefik-ip-${each.key}.txt"

echo "Fetching Traefik service IP for context: ${each.key}"

ip=$(kubectl get svc $${service_name} \
  --namespace $${namespace} \
  --context $${context}-traefik-demo \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Fallback to hostname if IP is not present (e.g., EKS)
if [ -z "$ip" ]; then
  ip=$(kubectl get svc $${service_name} \
    --namespace $${namespace} \
    --context $${context}-traefik-demo \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

if [[ "$context" == *"eks"* ]]; then
  echo "Resolving EKS hostname to IP..."
  max_retries=3
  retry_delay=60
  resolved_ips=()
  
  for ((i=1; i<=max_retries; i++)); do
    echo "DNS resolution attempt $i of $max_retries for hostname: $ip"
    echo "Running: dig +short \"$ip\""
    dig_result=$(dig +short "$ip" 2>&1)
    echo "Dig output: $dig_result"
    
    resolved_ips=($(echo "$dig_result" | grep -v '\.$'))
    echo "Resolved IPs: $${resolved_ips[*]}"
    
    if [ $${#resolved_ips[@]} -gt 0 ]; then
      echo "Successfully resolved $${#resolved_ips[@]} IP(s)"
      break
    fi
    
    if [ $i -lt $max_retries ]; then
      echo "No IPs resolved, waiting $retry_delay seconds before next attempt..."
      sleep $retry_delay
    else
      echo "WARNING: Could not resolve IP for $ip after $max_retries attempts, skipping $context" >&2
      exit 1
    fi
  done

  echo "$${resolved_ips[0]}" > "$ip_file"
else
  echo "$ip" > "$ip_file"
fi

echo "Saved IP(s) to $ip_file"
EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [azurerm_resource_group_template_deployment.traefik]
}

data "local_file" "traefik_ip" {
  for_each = var.enableTraefik ? toset(local.clusters) : []
  filename = "${path.module}/traefik-ip-${each.key}.txt"

  depends_on = [ null_resource.traefik_ips ]
}

output "traefikAKSIP" {
  value = var.enableAKS && var.enableTraefik ? local.traefik_ips["aks"] : null
}

output "traefikEKSIP" {
  value = var.enableEKS && var.enableTraefik ? local.traefik_ips["eks"] : null
}

output "traefikGKEIP" {
  value = var.enableGKE && var.enableTraefik ? local.traefik_ips["gke"] : null
}

resource "azurerm_arc_kubernetes_flux_configuration" "traefik_hub_management_dependencies" {
  name       = "traefik-hub-management-${each.value}"
  cluster_id = "${local.arc_cluster_prefix}/arc-${each.value}-traefik-demo"
  namespace  = "traefik"

  git_repository {
    url = "https://github.com/traefik-workshops/traefik-airlines.git"
    reference_type = "tag"
    reference_value = local.traefikAirlineVersion
  }

  kustomizations {
    name                       = "redis"
    path                       = "management/dependencies/redis"
    depends_on                 = []
    garbage_collection_enabled = false
    recreating_enabled         = false
    retry_interval_in_seconds  = 600
    sync_interval_in_seconds   = 600
    timeout_in_seconds         = 600
  }

  for_each   = var.enableTraefikHubManagement ? local.clusters : []
  depends_on = [ azurerm_arc_kubernetes_cluster_extension.flux, azurerm_resource_group_template_deployment.traefik ]
}