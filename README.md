# traefik-azure-arc-jumpstart-drops

This repository demonstrates how to create an Infrastructure as Code (IaC) multi-cluster Arc-enabled environment using Terraform. The deployment includes:

- Multiple Kubernetes clusters (AKS and k3d) connected to Azure Arc
- Traefik Proxy deployment from Azure Arc Marketplace
- Sample microservices application deployment using FluxCD
- Automated ingress management and TLS certificate generation using Let's Encrypt

## Architecture

The deployment is split into four main components:

1. **Clusters**: AKS and K3D cluster creation and Arc enablement
2. **Traefik**: Deployment of Traefik Proxy from Azure Arc Marketplace
3. **Routing**: Sample application deployment with basic HTTP routing
4. **TLS**: Automatic HTTPS with Let's Encrypt certificates

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

* [Install Helm 3](https://helm.sh/docs/intro/install/)

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

You can deploy the entire stack using the following command or deploy and test each component sequentially.

### Deploy the entire stack

```shell
terraform init
terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)"
```

### Deploy and test each component sequentially

1. [Clusters](1-clusters/README.md)
2. [Traefik](2-traefik/README.md)
3. [Routing](3-routing/README.md)
4. [TLS](4-tls/README.md)
