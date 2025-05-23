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
- **Multi-cluster Support**: Services accessible on both AKS and k3d clusters

## Prerequisites

* [Install or update Azure CLI to version 2.65.0 and above](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

* [Install k3d](https://k3d.io/stable/#installation)

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

Install Traefik Airlines k8s application
  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply -var="azureSubscriptionId=$(az account show --query id -o tsv)" -var-file="3-routing/terraform.tfvars"
  ```

## Testing

Verify that Traefik Airlines applications are exposed through Traefik through the k3d and AKS clusters. You can choose either of the clusters to test against.

### k3d

  ```shell
  url="localhost:8000"
  ```

### AKS

  ```shell
  url=$(terraform output -raw aksTraefikIp)
  ```
### Services

  Customers service:
  ```shell
  curl http://$url -H "Host: customers.traefik-airlines"
  ```

  Employees service:
  ```shell
  curl http://$url -H "Host: employees.traefik-airlines"
  ```

  Flights service:
  ```shell
  curl http://$url -H "Host: flights.traefik-airlines"
  ```

  Tickets service:
  ```shell
  curl http://$url -H "Host: tickets.traefik-airlines"
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

  ```shell
  terraform destroy -var="azureSubscriptionId=$(az account show --query id -o tsv)" -var-file="3-routing/terraform.tfvars"
  ```