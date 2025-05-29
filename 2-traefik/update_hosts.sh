#!/bin/bash
set -e

# Function to get IP from Terraform output
get_tf_ip() {
    local provider=$1
    local ip_output
    
    if ip_output=$(cd "$(dirname "$0")/.." && terraform output -raw "${provider}_traefik_ips" 2>/dev/null); then
        # For EKS, take the first IP if there are multiple
        if [[ "$provider" == "eks" ]]; then
            IFS=',' read -r -a ips <<< "$ip_output"
            echo "${ips[0]}"  # Return first IP for EKS
        else
            echo "$ip_output"
        fi
    else
        echo "Failed to get IP for $provider from Terraform" >&2
        return 1
    fi
}

# Initialize variables
TRAEFIK_AKS_IP=""
TRAEFIK_EKS_IP=""
TRAEFIK_GKE_IP=""

# Get AKS IP from Terraform
if AKS_IP=$(get_tf_ip aks 2>/dev/null); then
    TRAEFIK_AKS_IP=$AKS_IP
fi

# Get EKS IP from Terraform
if EKS_IP=$(get_tf_ip eks 2>/dev/null); then
    TRAEFIK_EKS_IP=$EKS_IP
fi

# Get GKE IP from Terraform
if GKE_IP=$(get_tf_ip gke 2>/dev/null); then
    TRAEFIK_GKE_IP=$GKE_IP
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
    echo "# Traefik dashboard entries - auto-generated from Terraform outputs"
    
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