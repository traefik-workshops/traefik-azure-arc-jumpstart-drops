# Deploy Traefik for Azure Arc to Arc-enabled Kubernetes clusters

## Overview

This drop demonstrates how to deploy Traefik Proxy for Azure Arc to Arc-enabled Kubernetes clusters using Terraform and ARM templates.

## Prerequisites
* Clone the Traefik Azure Arc Jumpstart GitHub repository

    ```shell
    git clone https://github.com/traefik/traefik-azure-arc-jumpstart-drops.git
    ```
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

## Deployment
* Install [Traefik for Azure Arc](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc/) application using Terraform
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="2-traefik/terraform.tfvars"
  ```

## Testing
Verify that Traefik was installed on both Azure Arc-enabled Kubernetes clusters:

  ```shell
  az connectedk8s show --name traefik-arc-aks-demo --resource-group $(terraform output -raw resource_group_name)
  az connectedk8s show --name traefik-arc-k3d-demo --resource-group $(terraform output -raw resource_group_name)
  ```

You can now view your Traefik dashboard locally.

[http://dashboard.traefik.localhost:8080](http://dashboard.traefik.localhost:8080)

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

  ```shell
  terraform destroy -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="2-traefik/terraform.tfvars"
  ```