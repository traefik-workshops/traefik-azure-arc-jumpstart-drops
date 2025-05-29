#!/bin/bash
set -e

# Function to deploy portal
deploy_portal() {
    local context=$1
    local ip=$2
    local namespace="traefik-airlines"
    local manifest="$(dirname "$0")/resources/traefik-airlines-portal.yaml"

    echo "Deploying Portal resources to $context with IP: $ip"
    
    # For EKS, we need to handle multiple IPs
    if [[ "$context" == *"eks"* ]]; then
        echo "Processing EKS IPs: $ip"
        IFS=',' read -r -a resolved_ips <<< "$ip"
        
        # Deploy for each resolved IP
        for i in "${!resolved_ips[@]}"; do
            current_ip="${resolved_ips[$i]}"
            echo "Deploying with IP $current_ip (${i})"
            sed "s/EXTERNAL_IP/$current_ip/g" "$manifest" | \
            sed "s/name: \"\(.*-ingress-secure\)\"/name: \"\\1-${i}\"/" | \
            kubectl apply --namespace "$namespace" --context "$context" -f -
        done
    else
        # For AKS and GKE, use the IP directly
        echo "Deploying with IP $ip"
        sed "s/EXTERNAL_IP/$ip/g" "$manifest" | \
        kubectl apply --namespace "$namespace" --context "$context" -f -
    fi
}

# Get IPs from Terraform
echo "Fetching IPs from Terraform..."
cd "$(dirname "$0")/.."  # Navigate to root directory if needed

# Check for each cloud provider's context and deploy
for provider in aks eks gke; do
    context="${provider}-traefik-demo"
    
    # Check if context exists
    if ! kubectl config get-contexts "$context" &>/dev/null; then
        echo "Context $context not found, skipping..."
        continue
    fi

    echo "Processing $provider..."
    
    # Get IP from Terraform output
    ip_output=$(terraform output -raw "${provider}_traefik_ips" 2>/dev/null || true)

    if [ -z "$ip_output" ]; then
        echo "WARNING: Could not get IP for $provider from Terraform, skipping..."
        continue
    fi

    deploy_portal "$context" "$ip_output"
done

echo "Portal deployment completed."