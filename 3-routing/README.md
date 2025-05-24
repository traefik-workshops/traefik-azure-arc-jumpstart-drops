# Deploy k8s applications to multiple Arc-enabled Kubernetes clusters using FluxCD and expose them using Traefik

## Overview

This drop demonstrates how to deploy and expose a microservices application across multiple Arc-enabled Kubernetes clusters using FluxCD and Traefik.

### Application Architecture

The Traefik Airlines demo application consists of four microservices:

- **Customers Service**: Manages customer data and loyalty programs
- **Employees Service**: Handles employee information and scheduling
- **Flights Service**: Manages flight schedules and availability
- **Tickets Service**: Processes ticket bookings and reservations

### Deployment Configuration

- **GitOps with FluxCD**: Automated deployment from Git repository
- **Traefik Integration**: Automatic service discovery and routing
- **Multi-cluster Support**: Services accessible on all the deployed Arc-enabled Kubernetes clusters

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

Install Traefik Airlines k8s application:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="3-routing/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

You can also enable the install on EKS and GKE clusters as well using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="3-routing/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```
  > **Note:** Make sure to copy the `extensions/eks.tf` and `extensions/gke.tf` files to the main directory if you are looking to use the EKS and GKE clusters.

## Testing

Verify that Traefik Airlines applications are exposed through Traefik through the k3d and AKS clusters. You can choose any of the clusters to test against.

  ```shell
  k3d_address="localhost:8000"
  aks_address="$(kubectl get svc traefik-aks --namespace traefik --context aks-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  eks_address="$(kubectl get svc traefik-eks --namespace traefik --context eks-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
  gke_address="$(kubectl get svc traefik-gke --namespace traefik --context gke-traefik-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  ```

### Services

  Customers service:
  ```shell
  curl http://$k3d_address -H "Host: customers.traefik-airlines"
  ```

  Employees service:
  ```shell
  curl http://$aks_address -H "Host: employees.traefik-airlines"
  ```

  Flights service:
  ```shell
  curl http://$eks_address -H "Host: flights.traefik-airlines"
  ```

  Tickets service:
  ```shell
  curl http://$gke_address -H "Host: tickets.traefik-airlines"
  ```

## Use FluxCD to deploy Traefik Airlines
Azure Arc Kubernetes' recommended GitOps tool is FluxCD. FluxCD is used to deploy the Traefik Airlines application to the AKS cluster using Terraform in the follow code snippet.

  ```hcl
  resource "azurerm_arc_kubernetes_flux_configuration" "traefik_airlines" {
    name       = "traefik-airlines"
    cluster_id = "traefik-arc-aks-demo"
    namespace  = "traefik-airlines"

    git_repository {
      url = "https://github.com/traefik-workshops/traefik-airlines.git"
      reference_type = "tag"
      reference_value = "v0.0.6"
    }

    kustomizations {
      name = "traefik-airlines"
    }
  }
  ```

## Teardown

To remove the Arc-enabled clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="3-routing/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

If you enabled EKS and GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="3-routing/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"