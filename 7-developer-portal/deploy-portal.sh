#!/bin/bash
set -e

# Function to deploy Portal resources
deploy_portal() {
    local context=$1
    local ip=$2
    local namespace="traefik-airlines"
    local manifest="$(dirname "$0")/resources/portal.yaml"

    echo "Deploying Portal resources to $context with IP: $ip"
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
    deploy_portal "aks-traefik-demo" "$AKS_IP"
else
    echo "WARNING: Could not get AKS IP from Terraform output"
fi

if [ -n "$EKS_IP" ]; then
    echo "Processing EKS..."
    deploy_portal "eks-traefik-demo" "$EKS_IP"
else
    echo "WARNING: Could not get EKS IP from Terraform output"
fi

if [ -n "$GKE_IP" ]; then
    echo "Processing GKE..."
    deploy_portal "gke-traefik-demo" "$GKE_IP"
else
    echo "WARNING: Could not get GKE IP from Terraform output"
fi

echo "Portal resources deployment completed."