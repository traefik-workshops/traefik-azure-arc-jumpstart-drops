#!/bin/bash
set -e

# Function to deploy TLS resources
deploy_tls_resources() {
    local context=$1
    local ip=$2
    local namespace="traefik-airlines"
    local manifest="$(dirname "$0")/resources/tls-routes.yaml"

    echo "Deploying TLS resources to $context with IP: $ip"
    sed "s/EXTERNAL_IP/$ip/g" "$manifest" | \
    kubectl apply --namespace "$namespace" --context "$context" -f -
}

# Get IPs from Terraform outputs
echo "Getting IPs from Terraform outputs..."
AKS_IP=$(terraform output -raw traefikAKSIP 2>/dev/null || true)
EKS_IP=$(terraform output -raw traefikEKSIP 2>/dev/null || true)
GKE_IP=$(terraform output -raw traefikGKEIP 2>/dev/null || true)

# Check for each cloud provider and deploy
if [ -n "$AKS_IP" ]; then
    echo "Processing AKS..."
    deploy_tls_resources "aks-traefik-demo" "$AKS_IP"
else
    echo "WARNING: Could not get AKS IP from Terraform output"
fi

if [ -n "$EKS_IP" ]; then
    echo "Processing EKS..."
    deploy_tls_resources "eks-traefik-demo" "$EKS_IP"
else
    echo "WARNING: Could not get EKS IP from Terraform output"
fi

if [ -n "$GKE_IP" ]; then
    echo "Processing GKE..."
    deploy_tls_resources "gke-traefik-demo" "$GKE_IP"
else
    echo "WARNING: Could not get GKE IP from Terraform output"
fi

echo "TLS resources deployment completed."