#!/bin/bash

# Function to safely get service address
get_service_address() {
    local context=$1
    local service_name=$2
    local namespace=$3
    
    # Check if context exists and is accessible
    if ! kubectl config get-contexts "$context" &>/dev/null; then
        echo "Context $context not found, skipping..." >&2
        return 1
    fi
    
    # Try to get the service IP/hostname
    local output
    if ! output=$(kubectl --context "$context" get svc "$service_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); then
        echo "Failed to get service $service_name in context $context, skipping..." >&2
        return 1
    fi
    
    if [ -z "$output" ]; then
        echo "No IP/hostname found for service $service_name in context $context, skipping..." >&2
        return 1
    fi
    
    echo "$output"
    return 0
}

# Initialize variables
TRAEFIK_AKS_IP=""
TRAEFIK_EKS_IP=""
TRAEFIK_GKE_IP=""

# Get AKS IP if context exists and service is available
if AKS_OUTPUT=$(get_service_address aks-traefik-demo traefik-aks traefik); then
    TRAEFIK_AKS_IP=$AKS_OUTPUT
fi

# Get EKS hostname and resolve to IP if context exists and service is available
if EKS_OUTPUT=$(get_service_address eks-traefik-demo traefik-eks traefik); then
    if EKS_IP=$(dig +short "$EKS_OUTPUT" | head -n 1); then
        TRAEFIK_EKS_IP=$EKS_IP
    else
        echo "WARNING: Could not resolve IP address for $EKS_OUTPUT" >&2
    fi
fi

# Get GKE IP if context exists and service is available
if GKE_OUTPUT=$(get_service_address gke-traefik-demo traefik-gke traefik); then
    TRAEFIK_GKE_IP=$GKE_OUTPUT
fi

# Create a temporary file
TMP_HOSTS=$(mktemp)

# Process the original hosts file
{
    # Keep only lines that don't contain our entries or headers
    while IFS= read -r line; do
        # Skip our managed entries and headers
        [[ "$line" == *"dashboard.traefik.aks"* ]] && continue
        [[ "$line" == *"dashboard.traefik.eks"* ]] && continue
        [[ "$line" == *"dashboard.traefik.gke"* ]] && continue
        [[ "$line" == *"Traefik dashboard entries"* ]] && continue
        
        # Keep all other lines
        echo "$line"
    done < "/etc/hosts"

    # Add our entries with a single header
    echo ""
    echo "# Traefik dashboard entries - auto-generated from kubectl outputs"
    
    # Only add entries for services that were successfully retrieved
    if [ -n "$TRAEFIK_AKS_IP" ]; then
        echo -e "$TRAEFIK_AKS_IP\t\tdashboard.traefik.aks"
    fi
    if [ -n "$TRAEFIK_EKS_IP" ]; then
        echo -e "$TRAEFIK_EKS_IP\t\tdashboard.traefik.eks"
    fi
    if [ -n "$TRAEFIK_GKE_IP" ]; then
        echo -e "$TRAEFIK_GKE_IP\t\tdashboard.traefik.gke"
    fi
} > "$TMP_HOSTS"

# Replace the original hosts file
if sudo cp "$TMP_HOSTS" "/etc/hosts"; then
    rm "$TMP_HOSTS"
    echo "Successfully updated /etc/hosts with available Traefik endpoints"
    
    # Display the changes
    echo ""
    echo "Current Traefik endpoints:"
    if [ -n "$TRAEFIK_AKS_IP" ]; then echo "- AKS: http://dashboard.traefik.aks:8080"; fi
    if [ -n "$TRAEFIK_EKS_IP" ]; then echo "- EKS: http://dashboard.traefik.eks:8080"; fi
    if [ -n "$TRAEFIK_GKE_IP" ]; then echo "- GKE: http://dashboard.traefik.gke:8080"; fi
    if [ -z "$TRAEFIK_AKS_IP" ] && [ -z "$TRAEFIK_EKS_IP" ] && [ -z "$TRAEFIK_GKE_IP" ]; then
        echo "No Traefik endpoints were available"
    fi
else
    echo "Error updating /etc/hosts" >&2
    rm "$TMP_HOSTS"
    exit 1
fi