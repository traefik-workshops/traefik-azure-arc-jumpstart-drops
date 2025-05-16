# Deploy and Arc-enable AKS and k3d clusters with Terraform

## Overview

This drop demonstrates how to deploy and Arc-enable both AKS and k3d clusters using Terraform. The deployment includes:

- **AKS Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

- **k3d Cluster**:
  - Local Kubernetes cluster using k3s in Docker
  - Exposed ports for ingress (8000, 8443, 8080)
  - Azure Arc extension installation

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
Install AKS and k3d clusters using Terraform:
  ```shell
  terraform init
  terraform apply \
    -var="azure_subscription_id=$(az account show --query id -o tsv)" \
    -var-file="1-clusters/terraform.tfvars"
  ```

## Testing
Verify that both AKS and k3d have been created successfully, and are accessible using `kubectl`:

  For AKS cluster:
  ```shell
  kubectl --context=$(terraform output -raw aks_cluster_name) get nodes
  ```

  For k3d cluster:
  ```shell
  kubectl --context=$(terraform output -raw k3d_cluster_name) get nodes
  ```

## Teardown
Remove AKS and k3d clusters using Terraform:
  ```shell
  terraform destroy -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="1-clusters/terraform.tfvars"
  ```