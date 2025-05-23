# Multi-cluster API Management with Traefik Hub

## Overview

This drop demonstrates how to enable automatic HTTPS for your services using Traefik's Let's Encrypt integration.

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

* [Optional] If you are looking to deploy EKS and GKE clusters, make sure to copy the `extensions/eks.tf` and `extensions/gke.tf` files to the main directory.

```shell
cp extensions/eks.tf .
cp extensions/gke.tf .
```

* Accept Terms for Traefik for Azure Arc. You can either choose to run this command to accept the Traefik terms or accept the terms in the Azure Arc [marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc).

  ```shell
  az term accept --publisher containous --product traefik-on-arc --plan traefik-byol
  ```

## Getting Started

You need a [Traefik Hub](https://hub.traefik.io/) account. You can sign up [here](https://hub.traefik.io/). You you have please navigate to the [gateways](https://hub.traefik.io/gateways) section and create a gateway per cluster. You will need the license key for each cluster to deploy the Traefik instances. You can follow this guide to grab the license key for each cluster: [here](https://doc.traefik.io/traefik-hub/operations/installation#before-you-begin).

Clone the Traefik Azure Arc Jumpstart GitHub repository

  ```shell
  git clone https://github.com/traefik/traefik-azure-arc-jumpstart-drops.git
  ```

Update Traefik configuration to handle Let's Encrypt certificates:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="5-api-management/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="traefikHubK3DLicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_1>" \
    -var="traefikHubAKSLicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_2>"
  ```

You can also enable the install on EKS and GKE clusters as well using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="5-api-management/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true" \
    -var="traefikHubK3DLicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_1>" \
    -var="traefikHubAKSLicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_2>" \
    -var="traefikHubEKSLicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_3>" \
    -var="traefikHubGKELicenseKey=<YOUR_TRAEFIK_HUB_LICENSE_KEY_4>"
  ```
  > **Note:** Make sure to copy the `extensions/eks.tf` and `extensions/gke.tf` files to the main directory if you are looking to use the EKS and GKE clusters.

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
