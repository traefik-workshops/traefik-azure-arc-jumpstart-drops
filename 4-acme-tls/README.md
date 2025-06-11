# Secure Traefik Airlines applications using Let's Encrypt and Traefik automated certificate management

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
  git clone https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops.git
  ```

Update Traefik configuration to handle Let's Encrypt certificates:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

  > **Note:** AKS cluster is enabled by default. You can turn that off using the `enableAKS` variable.

You can also enable the install on k3d, EKS or GKE clusters as well using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableK3D=true" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```

  > **Note:** You must create those clusters before hand. Please refer to the [clusters](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/tree/main/1-clusters) drop for more information.

Deploy TLS enabled routes to the cluster of your choice. Make sure to replace the `EXTERNAL_IP` with the external IP of your Traefik instance on each cluster. You can run this manually using the following commands or run the `deploy-tls.sh` script to deploy the TLS enabled routes to all clusters.

### AKS

  ```shell
  aks_ip="$(terraform output -raw traefikAKSIP)"
  sed "s/EXTERNAL_IP/$aks_ip/g" "4-acme-tls/resources/tls-routes.yaml" | \
  kubectl apply \
    --namespace "traefik-airlines" \
    --context "aks-traefik-demo" -f -;
  ```

### AKS/EKS/GKE

  ```shell
  ./4-acme-tls/deploy-tls.sh
  ```

  > **Note:** You may need to change the script permissions to make it executable:

  ```shell
  chmod +x ./4-acme-tls/deploy-tls.sh
  ```

  Example output:

  ```shell
  Processing AKS...
  Deploying TLS resources to aks-traefik-demo with IP: 40.125.40.112
  ingressroute.traefik.io/customers-ingress-secure created
  ingressroute.traefik.io/employees-ingress-secure created
  ingressroute.traefik.io/flights-ingress-secure created
  ingressroute.traefik.io/tickets-ingress-secure created
  Processing EKS...
  Deploying TLS resources to eks-traefik-demo with IP: 54.67.105.168
  ingressroute.traefik.io/customers-ingress-secure created
  ingressroute.traefik.io/employees-ingress-secure created
  ingressroute.traefik.io/flights-ingress-secure created
  ingressroute.traefik.io/tickets-ingress-secure created
  Processing GKE...
  Deploying TLS resources to gke-traefik-demo with IP: 34.106.210.103
  ingressroute.traefik.io/customers-ingress-secure created
  ingressroute.traefik.io/employees-ingress-secure created
  ingressroute.traefik.io/flights-ingress-secure created
  ingressroute.traefik.io/tickets-ingress-secure created
  TLS resources deployment completed.
  ```

## Testing

Verify that Traefik Airlines applications are exposed through Traefik on the Arc-enabled clusters. You can choose any of the clusters to test against.

  ```shell
  aks_address=$(terraform output -raw traefikAKSIP)
  eks_address=$(terraform output -raw traefikEKSIP)
  gke_address=$(terraform output -raw traefikGKEIP)
  ```

### Customers service

  ```shell
  curl https://customers.airlines.traefik.${aks_address}.sslip.io
  ```

### Employees service

  ```shell
  curl https://employees.airlines.traefik.${aks_address}.sslip.io
  ```

### Flights service

  ```shell
  curl https://flights.airlines.traefik.${eks_address}.sslip.io
  ```

### Tickets service

  ```shell
  curl https://tickets.airlines.traefik.${gke_address}.sslip.io
  ```

## Teardown

To remove the Arc-enabled clusters, run the following commands:

  ```shell
  terraform destroy \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

If you enabled k3d, EKS or GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableK3D=true" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```

### Extra Clusters

If you want to destroy the extra clusters, run the following commands:

#### k3d

  ```shell
  terraform -chdir=./1-clusters/k3d destroy
  ```

#### EKS

  ```shell
  terraform -chdir=./1-clusters/eks destroy
  ```

#### GKE

  ```shell
  terraform -chdir=./1-clusters/gke destroy \
    -var="googleProjectId=$(gcloud config get-value project)"
  ```
