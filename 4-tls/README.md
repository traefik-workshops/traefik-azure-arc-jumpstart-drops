# Secure Traefik Airlines application using Let's Encrypt and Traefik automated certificate management

## Overview

This drop demonstrates how to enable automatic HTTPS for your services using Traefik's Let's Encrypt integration.

### TLS Configuration

The deployment configures Traefik with:

- **Automatic Certificate Management**: Using Let's Encrypt to automatically generate and renew certificates
- **HTTP Challenge**: For domain ownership verification
- **Wildcard Domains**: Using sslip.io for easy testing

### Important Notes

- AKS/EKS/GKE clusters support Let's Encrypt integration but k3d does not as it requires a public IP
- Certificates are automatically stored and renewed by Traefik

## Prerequisites

* [Install or update Azure CLI to version 2.65.0 and above](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

* [Optional] [Install k3d](https://k3d.io/stable/#installation)

* [Optional] [Install and configure awscli if you plan to deploy EKS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

* [Optional] [Install and configure gcloud if you plan to deploy GKE](https://cloud.google.com/sdk/docs/install)

* [Optional] [Install gke-cloud-auth-plugin if you plan to deploy GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)

* [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

* [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

* Create Azure service principal (SP)

  The Azure service principal assigned with the "Contributor" role is required to complete the scenario and its related automation. To create it, log in to your Azure account run the below command (you could also do this in [Azure Cloud Shell](https://shell.azure.com/)).

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    az ad sp create-for-rbac -n "<Unique SP Name>" --role "Contributor" --scopes /subscriptions/$subscriptionId
    ```

    For example:

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    az ad sp create-for-rbac -n "JumpstartArcK8s" --role "Contributor" --scopes /subscriptions/$subscriptionId
    ```

    Output should look like this:

    ```json
    {
    "appId": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "displayName": "JumpstartArcK8s",
    "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    ```

    > **Note:** If you create multiple subsequent role assignments on the same service principal, your client secret (password) will be destroyed and recreated each time. Therefore, make sure you grab the correct password.

* [Enable subscription with](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider) the two resource providers for Azure Arc-enabled Kubernetes. Registration is an asynchronous process, and registration may take approximately 10 minutes.

  ```shell
  az provider register --namespace Microsoft.Kubernetes
  az provider register --namespace Microsoft.KubernetesConfiguration
  az provider register --namespace Microsoft.ExtendedLocation
  az provider register --namespace Microsoft.ContainerService
  ```

  You can monitor the registration process with the following commands:

  ```shell
  az provider show -n Microsoft.Kubernetes -o table
  az provider show -n Microsoft.KubernetesConfiguration -o table
  az provider show -n Microsoft.ExtendedLocation -o table
  az provider show -n Microsoft.ContainerService -o table
  ```

* Install the Azure Arc for Kubernetes CLI extensions ***connectedk8s*** and ***k8s-configuration***:

  ```shell
  az extension add --name connectedk8s
  az extension add --name k8s-configuration
  ```

  > **Note:** If you already used this guide before and/or have the extensions installed, use the below commands.

  ```shell
  az extension update --name connectedk8s
  az extension update --name k8s-configuration
  ```

* Accept Terms for Traefik for Azure Arc. You can either choose to run this command to accept the Traefik terms or accept the terms in the Azure Arc [marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc).

  ```shell
  az term accept --publisher containous --product traefik-on-arc --plan traefik-byol
  ```

## Getting Started

Clone the Traefik Azure Arc Jumpstart GitHub repository

  ```shell
  git clone https://github.com/traefik/traefik-azure-arc-jumpstart-drops.git
  ```

Update Traefik configuration to handle Let's Encrypt certificates:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="4-tls/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

You can also enable the install on EKS and GKE clusters as well using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="4-tls/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```
  > **Note:** Make sure to copy the `extensions/eks.tf` and `extensions/gke.tf` files to the main directory if you are looking to use the EKS and GKE clusters.

Deploy TLS enabled routes to the cluster of your choice. Make sure to replace the `EXTERNAL_IP` with the external IP of your Traefik instance on each cluster. You can run this manually using the following commands or run the `deploy-tls.sh` script to deploy the TLS enabled routes to all clusters.

### AKS

  ```shell
  aks_ip="$(kubectl get svc traefik-aks --namespace traefik --context aks-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  sed "s/EXTERNAL_IP/$aks_ip/g" "4-tls/resources/traefik-airlines-tls.yaml" | \
  kubectl apply \
    --namespace "traefik-airlines" \
    --context "aks-traefik-demo" -f -;
  ```

### AKS/EKS/GKE

  ```shell
  ./deploy-tls.sh
  ```

  Example output:

  ```shell
  Processing aks...
  Deploying TLS resources to aks-traefik-demo with IP/hostname: 20.245.254.148
  Deploying with IP 20.245.254.148
  ingressroute.traefik.io/customers-ingress-secure created
  ingressroute.traefik.io/employees-ingress-secure created
  ingressroute.traefik.io/flights-ingress-secure created
  ingressroute.traefik.io/tickets-ingress-secure created
  Processing eks...
  Deploying TLS resources to eks-traefik-demo with IP/hostname: a2f9aea9f80644d1fbfdd69a2f8e19e1-67ea3e06c2d7552c.elb.us-west-1.amazonaws.com
  Resolving EKS hostname to IP...
  Deploying with IP 184.169.136.137 (0)
  ingressroute.traefik.io/customers-ingress-secure-0 created
  ingressroute.traefik.io/employees-ingress-secure-0 created
  ingressroute.traefik.io/flights-ingress-secure-0 created
  ingressroute.traefik.io/tickets-ingress-secure-0 created
  Deploying with IP 52.8.123.158 (1)
  ingressroute.traefik.io/customers-ingress-secure-1 created
  ingressroute.traefik.io/employees-ingress-secure-1 created
  ingressroute.traefik.io/flights-ingress-secure-1 created
  ingressroute.traefik.io/tickets-ingress-secure-1 created
  Processing gke...
  Deploying TLS resources to gke-traefik-demo with IP/hostname: 34.106.133.173
  Deploying with IP 34.106.133.173
  ingressroute.traefik.io/customers-ingress-secure created
  ingressroute.traefik.io/employees-ingress-secure created
  ingressroute.traefik.io/flights-ingress-secure created
  ingressroute.traefik.io/tickets-ingress-secure created
  TLS resources deployment completed.
  ```

## Testing

Verify that Traefik Airlines applications are exposed through Traefik through the k3d and AKS clusters. You can choose any of the clusters to test against.

### AKS/GKE

  ```shell
  aks_address="$(kubectl get svc traefik-aks --namespace traefik --context aks-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  gke_address="$(kubectl get svc traefik-gke --namespace traefik --context gke-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  ```

### EKS

  ```shell
  eks_ips=$(dig +short "$(kubectl get svc traefik-eks --namespace traefik --context eks-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')")
  eks_address_0=$(echo $eks_ips | sed -n 1p)
  eks_address_1=$(echo $eks_ips | sed -n 2p)

  ```

### Customers service

  ```shell
  curl https://customers.traefik-airlines.${aks_address}.sslip.io
  ```

### Employees service

  ```shell
  curl https://employees.traefik-airlines.${gke_address}.sslip.io
  ```

### Flights service

  ```shell
  curl https://flights.traefik-airlines.${eks_address_0}.sslip.io
  ```

### Tickets service

  ```shell
  curl https://tickets.traefik-airlines.${eks_address_0}.sslip.io
  ```

## Teardown

To remove the Arc-enabled clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="4-tls/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

If you enabled EKS and GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="4-tls/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
