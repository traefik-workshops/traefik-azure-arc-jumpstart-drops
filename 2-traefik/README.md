# Deploy Traefik for Azure Arc to Arc-enabled Kubernetes clusters

## Overview

This drop demonstrates how to deploy Traefik Proxy for Azure Arc to Arc-enabled Kubernetes clusters using Terraform and ARM templates. Traefik is a leading modern open source reverse proxy and ingress controller that makes deploying services and APIs easy. Traefik integrates with your existing infrastructure components and configures itself automatically and dynamically.

## Prerequisites

* [Install or update Azure CLI to version 2.65.0 and above](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

* [Install k3d](https://k3d.io/stable/#installation)

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

  > **Note:** You must accept the terms for Traefik for Azure Arc before you can deploy it to your Arc-enabled Kubernetes clusters. You can either choose to run this command to accept the Traefik terms or accept the terms in the Azure Arc [marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc).

    ```shell
    az term accept --publisher containous --product traefik-on-arc --plan traefik-byol
    ```

Clone the Traefik Azure Arc Jumpstart GitHub repository

  ```shell
  git clone https://github.com/traefik/traefik-azure-arc-jumpstart-drops.git
  ```

Install [Traefik for Azure Arc](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc/) application using Terraform
  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

You can also enable the install on EKS and GKE clusters as well using Terraform:
  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```
  > **Note:** Make sure to copy the `extensions/eks.tf` and `extensions/gke.tf` files to the main directory if you are looking to use the EKS and GKE clusters.

## Testing

Verify that Traefik was installed on both Azure Arc-enabled Kubernetes clusters:

  ```shell
  az connectedk8s show --name arc-$(terraform output -raw k3dClusterName) --resource-group $(terraform output -raw resourceGroupName)
  az connectedk8s show --name arc-$(terraform output -raw aksClusterName) --resource-group $(terraform output -raw resourceGroupName)
  az connectedk8s show --name arc-$(terraform output -raw eksClusterName) --resource-group $(terraform output -raw resourceGroupName)
  az connectedk8s show --name arc-$(terraform output -raw gkeClusterName) --resource-group $(terraform output -raw resourceGroupName)
  ```

You can now view your Traefik dashboard locally at [http://dashboard.traefik.localhost:8080](http://dashboard.traefik.localhost:8080)

## ARM Template Example

To be able to deploy Arc specific marketplace applications with Terraform, you need to use the `azurerm_resource_group_template_deployment` resource. You can simply copy the ARM template from the Azure portal when reviewing the marketplace application install, and paste it into the `template_content` variable in the `azurerm_resource_group_template_deployment` resource. The [traefik.tf](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/blob/main/traefik.tf) file shows an example of how to deploy the Traefik for Azure Arc marketplace application using ARM templates with Terraform.

  ```hcl
  resource "azurerm_resource_group_template_deployment" "traefik" {
    name                = "traefik"
    resource_group_name = azurerm_resource_group.traefik_demo.name
    deployment_mode     = "Incremental"
    template_content = <<TEMPLATE
  {
      "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "outputs": {},
      "parameters": {},
      "resources": [
          {
              "apiVersion": "2023-05-01",
              "name": "traefik",
              "plan": {
                  "name": "traefik-byol",
                  "product": "traefik-on-arc",
                  "publisher": "containous"
              },
              "properties": {
                  "autoUpgradeMinorVersion": "true",
                  "configurationProtectedSettings": {},
                  "configurationSettings": ${jsonencode(local.config)},
                  "extensionType": "TraefikLabs.TraefikProxyOnArc",
                  "releaseTrain": "stable",
                  "scope": {
                      "cluster": {
                          "releaseNamespace": "traefik"
                      }
                  }
              },
              "scope": "Microsoft.Kubernetes/connectedClusters/traefik-arc-aks-demo",
              "type": "Microsoft.KubernetesConfiguration/extensions"
          }
      ]
  }
  TEMPLATE
  }
  ```

## Teardown

To remove the Arc-enabled clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

If you enabled EKS and GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```