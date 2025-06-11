# Deploy Traefik for Azure Arc to Arc-enabled Kubernetes clusters

## Overview

This drop demonstrates how to deploy Traefik Proxy for Azure Arc to Arc-enabled Kubernetes clusters using Terraform and ARM templates. 

Traefik is an open-source Application Proxy that makes publishing your services a fun and easy experience. It receives requests on behalf of your system, identifies which components are responsible for handling them, and routes them securely.

What sets Traefik apart, besides its many features, is that it automatically discovers the right configuration for your services. The magic happens when Traefik inspects your infrastructure, where it finds relevant information and discovers which service serves which request.

Traefik is natively compliant with every major cluster technology, such as Kubernetes, Docker Swarm, AWS, and the [list goes on](https://doc.traefik.io/traefik/reference/install-configuration/providers/overview/); and can handle many at the same time. (It even works for legacy software running on bare metal.)

With Traefik, there is no need to maintain and synchronize a separate configuration file: everything happens automatically, in real time (no restarts, no connection interruptions). With Traefik, you spend time developing and deploying new features to your system, not on configuring and maintaining its working state.

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

  The Azure service principal assigned with the "Owner" role is required to complete the scenario and its related automation. To create it, log in to your Azure account run the below command (you could also do this in [Azure Cloud Shell](https://shell.azure.com/)).

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    az ad sp create-for-rbac -n "<Unique SP Name>" --role "Owner" --scopes /subscriptions/$subscriptionId
    ```

    For example:

    ```shell
    az login
    subscriptionId=$(az account show --query id --output tsv)
    az ad sp create-for-rbac -n "JumpstartArcK8s" --role "Owner" --scopes /subscriptions/$subscriptionId
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

  > **Note:** You must accept the terms for Traefik for Azure Arc before you can deploy it to your Arc-enabled Kubernetes clusters. You can either choose to run this command to accept the Traefik terms or accept the terms in the Azure Arc [marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc).

    ```shell
    az term accept --publisher containous --product traefik-on-arc --plan traefik-byol
    ```

Clone the Traefik Azure Arc Jumpstart GitHub repository

  ```shell
  git clone https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops.git
  ```

Install [Traefik for Azure Arc](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc/) application using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

  > **Note:** AKS cluster is enabled by default. You can turn that off using the `enableAKS` variable.

You can also enable the install on k3d, EKS or GKE clusters as well using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableK3D=true" \
    -var="enableGKE=true" \
    -var="enableEKS=true"
  ```

  > **Note:** You must create those clusters before hand. Please refer to the [clusters](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/tree/main/1-clusters) drop for more information.

## Testing

Verify that Traefik was installed on both Azure Arc-enabled Kubernetes clusters:

  ```shell
  az connectedk8s show --name arc-aks-traefik-demo --resource-group traefik-demo
  az connectedk8s show --name arc-k3d-traefik-demo --resource-group traefik-demo
  az connectedk8s show --name arc-eks-traefik-demo --resource-group traefik-demo
  az connectedk8s show --name arc-gke-traefik-demo --resource-group traefik-demo
  ```

You can now view your Traefik dashboard locally at [http://dashboard.traefik.localhost:8080](http://dashboard.traefik.localhost:8080) if you enabled the k3d cluster.

If you would like to view the Traefik dashboard on the rest of the Arc-enabled Kubernetes clusters you can run the following command to update your `/etc/hosts` file with the Arc-enabled Kubernetes cluster IP addresses and demo domain names:

  ```shell
  sudo ./2-traefik/update_hosts.sh
  ```

  > **Note:** You may need to change the script permissions to make it executable:

  ```shell
  chmod +x ./2-traefik/update_hosts.sh
  ```

Example output to `/etc/hosts` file:

  ```shell
  # Traefik dashboard entries - auto-generated from kubectl outputs
  20.253.255.25		  dashboard.traefik.aks
  54.219.221.253		dashboard.traefik.eks
  34.106.34.172		  dashboard.traefik.gke
  ```

Example output of `sudo ./2-traefik/update_hosts.sh`:

  ```shell
  Successfully updated /etc/hosts with available Traefik endpoints

  Current Traefik endpoints:
  - AKS: http://dashboard.traefik.aks:8080
  - EKS: http://dashboard.traefik.eks:8080
  - GKE: http://dashboard.traefik.gke:8080
  ```

You can now view your Traefik dashboard on the rest Arc-enabled Kubernetes clusters at:

[http://dashboard.traefik.aks:8080](http://dashboard.traefik.aks:8080)
[http://dashboard.traefik.eks:8080](http://dashboard.traefik.eks:8080)
[http://dashboard.traefik.gke:8080](http://dashboard.traefik.gke:8080)

You can run the following commands to get the IP addresses of the Arc-enabled Kubernetes clusters if you choose to update your `/etc/hosts` file manually:

  ```shell
  terraform output traefikAKSIP
  terraform output traefikEKSIP
  terraform output traefikGKEIP
  ```

## ARM Template Example

To be able to deploy Arc specific marketplace applications with Terraform, you need to use the `azurerm_resource_group_template_deployment` resource. You can simply copy the ARM template from the Azure Marketplace portal when reviewing the marketplace application install, and paste it into the `template_content` variable in the `azurerm_resource_group_template_deployment` resource. The [traefik.tf](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/blob/main/traefik.tf) file is an example of how to deploy the Traefik for Azure Arc marketplace application using ARM templates with Terraform.

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

To remove the Arc-enabled AKS cluster, run the following commands:

  ```shell
  terraform destroy \
    -var-file="2-traefik/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

If you enabled k3d, EKS or GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="2-traefik/terraform.tfvars" \
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
