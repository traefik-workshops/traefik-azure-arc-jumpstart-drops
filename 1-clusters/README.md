# Deploy Arc-enabled AKS, k3d, EKS, and GKE clusters with Terraform

## Overview

This drop demonstrates how to deploy and Arc-enable AKS, k3d, EKS, and GKE clusters using Terraform. The deployment includes:

- **AKS Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

- **k3d Cluster**:
  - Local Kubernetes cluster using k3s in Docker
  - Exposed ports for ingress (8000, 8443, 8080)
  - Azure Arc extension installation

- **EKS Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

- **GKE Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

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

Clone the Traefik Azure Arc Jumpstart GitHub repository:

  ```shell
  git clone https://github.com/traefik/traefik-azure-arc-jumpstart-drops.git
  ```

Install AKS cluster using Terraform:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="1-clusters/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

You can also enable the install of k3d, EKS or GKE clusters as well using Terraform:

#### k3d

  ```shell
  terraform -chdir=./1-clusters/k3d init
  terraform -chdir=./1-clusters/k3d apply
  ```

#### EKS

  ```shell
  terraform -chdir=./1-clusters/eks init
  terraform -chdir=./1-clusters/eks apply
  ```

#### GKE

  ```shell
  terraform -chdir=./1-clusters/gke init
  terraform -chdir=./1-clusters/gke apply \
    -var="googleProjectId=$(gcloud config get-value project)"
  ```

Once you finish install all the extra clusters you can run the following command to connect them to Azure Arc:

  ```shell
  cd traefik-azure-arc-jumpstart-drops
  terraform init
  terraform apply \
    -var-file="1-clusters/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableK3D=true" \
    -var="enableEKS=true" \
    -var="enableGKE=true"
  ```

## Testing

Verify that the AKS, k3d, EKS, and GKE clusters have been created successfully, and are accessible using `kubectl`:

  ```shell
  kubectl --context=aks-traefik-demo get nodes
  kubectl --context=k3d-traefik-demo get nodes
  kubectl --context=eks-traefik-demo get nodes
  kubectl --context=gke-traefik-demo get nodes
  ```

## Arc-enable clusters

Connecting Kubernetes clusters to Azure Arc is only possible through the Azure CLI and the Terraform null resource. Here is an example of how to connect a k3d cluster to Azure Arc. You can view the example setup under [clusters.tf](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/blob/main/clusters.tf).

  ```hcl
  resource "null_resource" "arc_k3d_cluster" {
    provisioner "local-exec" {
      command = <<EOT
        az connectedk8s connect \
          --kube-context ${local.k3d_cluster_name} \
          --name "arc-${local.k3d_cluster_name}" \
          --resource-group ${azurerm_resource_group.traefik_demo.name}
      EOT
    }

    provisioner "local-exec" {
      when = destroy
      command = <<EOT
        az connectedk8s delete --force --yes \
          --name "arc-k3d-traefik-demo" \
          --resource-group "traefik-demo"

        kubectl config delete-context "k3d-traefik-demo" 2>/dev/null || true
      EOT
    }

    count      = var.enableK3D ? 1 : 0
    depends_on = [ module.k3d ]
  }
  ```

## Teardown

To remove the Arc-enabled clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="1-clusters/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)"
  ```

  > **Note:** AKS cluster is enabled by default. You can turn that off using the `enableAKS` variable.

If you enabled k3d, EKS or GKE clusters, run the following commands:

  ```shell
  terraform destroy \
    -var-file="1-clusters/terraform.tfvars" \
    -var="azureSubscriptionId=$(az account show --query id -o tsv)" \
    -var="googleProjectId=$(gcloud config get-value project)" \
    -var="enableK3D=true" \
    -var="enableEKS=true" \
    -var="enableGKE=true"
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
