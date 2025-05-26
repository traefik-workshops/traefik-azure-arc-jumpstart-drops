#!/bin/bash
set -e

# Function to deploy TLS resources
deploy_tls_resources() {
    local context=$1
    local ip=$2
    local namespace="traefik-airlines"
    local manifest="$(dirname "$0")/resources/traefik-airlines-tls.yaml"

    echo "Deploying TLS resources to $context with IP/hostname: $ip"
    
    # For EKS, we need to resolve the hostname to IP
    if [[ "$context" == *"eks"* ]]; then
        echo "Resolving EKS hostname to IP..."
        resolved_ips=($(dig +short "$ip" | grep -v '\.$'))
        if [ ${#resolved_ips[@]} -eq 0 ]; then
            echo "WARNING: Could not resolve IP for $ip, skipping $context"
            return 1
        fi

        # Deploy for each resolved IP
        for i in "${!resolved_ips[@]}"; do
            echo "Deploying with IP ${resolved_ips[$i]} (${i})"
            sed "s/EXTERNAL_IP/${resolved_ips[$i]}/g" "$manifest" | \
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

# Check for each cloud provider's context and deploy
for provider in aks eks gke; do
    context="${provider}-traefik-demo"
    
    # Check if context exists
    if ! kubectl config get-contexts "$context" &>/dev/null; then
        echo "Context $context not found, skipping..."
        continue
    fi

    echo "Processing $provider..."
    
    # Get the service type (LoadBalancer) and IP/hostname
    if [ "$provider" = "eks" ]; then
        # EKS returns hostname
        ip=$(kubectl get svc "traefik-${provider}" -n traefik --context "$context" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    else
        # AKS and GKE return IP
        ip=$(kubectl get svc "traefik-${provider}" -n traefik --context "$context" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    fi

    if [ -z "$ip" ]; then
        echo "WARNING: Could not get IP/hostname for $provider, skipping..."
        continue
    fi

    deploy_tls_resources "$context" "$ip"
done

echo "TLS resources deployment completed."
