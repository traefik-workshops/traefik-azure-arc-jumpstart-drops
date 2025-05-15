# IaC Arc-enabled Kubernetes multi-cluster deployment using Terraform

This module demonstrates how to deploy and Arc-enable both AKS and k3d clusters using Terraform. The deployment includes:

- **AKS Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

- **k3d Cluster**:
  - Local Kubernetes cluster using k3s in Docker
  - Exposed ports for ingress (8000, 8443, 8080)
  - Azure Arc extension installation

> **Note:** Please refer to the [README](../README.md) for a list of requirements.

## Configuration

The deployment can be customized through the following variables in `terraform.tfvars`:

- `enable_aks`: Enable/disable AKS cluster deployment
- `enable_k3d`: Enable/disable k3d cluster deployment
- `aks_cluster_machine_type`: VM size for AKS nodes

## Deployment
Install AKS and k3d clusters using Terraform:
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="1-clusters/terraform.tfvars"
  ```

## Verify
Verify that both AKS and k3d have been created successfully, and are accessible using `kubectl`:

  For AKS cluster:
  ```shell
  kubectl --context=$(terraform output -raw aks_cluster_name) get nodes
  ```

  For k3d cluster:
  ```shell
  kubectl --context=$(terraform output -raw k3d_cluster_name) get nodes
  ```

## How to connect your clusters to Azure Arc with Terraform

Connecting Kuberenets clusters to Azure Arc is only possible through the Azure CLI and the Terraform null resource. Here is an example of how to connect a k3d cluster to Azure Arc. You can view the setup for both clusters under [AKS](../aks.tf) and [k3d](../k3d.tf)

```hcl
resource "null_resource" "arc_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      az connectedk8s connect \
        --kube-context k3d-traefik-demo \
        --name ${local.arc_k3d_cluster_name} \
        --resource-group ${azurerm_resource_group.traefik_demo.name}
    EOT
  }
}
```

------
:house: [HOME](../README.md) | [Traefik](../2-traefik/README.md) :arrow_forward:
