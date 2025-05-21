#!/bin/bash

# Get Terraform outputs
TRAEFIK_AKS_IP=$(terraform output -raw traefikAKSAddress)
TRAEFIK_EKS_HOST=$(terraform output -raw traefikEKSAddress)
TRAEFIK_GKE_IP=$(terraform output -raw traefikGKEAddress)

# Resolve EKS hostname to IP (get first IP if multiple)
TRAEFIK_EKS_IP=$(dig +short "$TRAEFIK_EKS_HOST" | head -n 1)

if [ -z "$TRAEFIK_EKS_IP" ]; then
    echo "ERROR: Could not resolve IP address for $TRAEFIK_EKS_HOST"
    exit 1
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
    echo "# Traefik dashboard entries - auto-generated from Terraform outputs"
    echo -e "$TRAEFIK_AKS_IP\t\tdashboard.traefik.aks"
    echo -e "$TRAEFIK_EKS_IP\t\tdashboard.traefik.eks"
    echo -e "$TRAEFIK_GKE_IP\t\tdashboard.traefik.gke"
} > "$TMP_HOSTS"

# Replace the original hosts file
sudo cp "$TMP_HOSTS" "/etc/hosts" && \
rm "$TMP_HOSTS" && \
echo "Successfully updated /etc/hosts with current Terraform outputs" || \
echo "Error updating /etc/hosts"

# Display the changes
echo -e "\nYou can now view the Traefik dashboards at:"
echo -e "http://dashboard.traefik.aks:8080"
echo -e "http://dashboard.traefik.eks:8080"
echo -e "http://dashboard.traefik.gke:8080"