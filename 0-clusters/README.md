# IaC Arc-enabled Kubernetes multi-cluster deployment using Terraform

The following Azure Arc Jumpstart Drop demonstrates how to deploy AKS and K3D clusters and connect them to Azure Arc with Terraform.

  > **Note:** Please refer to the [README](../README.md) for a list of requirements.

## Deployment
Install AKS and K3D clusters using terraform
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="0-clusters/terraform.tfvars"
  ```

## Test
Verify that both AKS and K3D have been created successfully, and are accessible using `kubectl`:

  For AKS cluster:
  ```shell
  kubectl --context=$(terraform output -raw aks_cluster_name) get nodes
  ```

  For K3D cluster:
  ```shell
  kubectl --context=$(terraform output -raw k3d_cluster_name) get nodes
  ```

## How to connect your clusters to Azure Arc with Terraform

Connecting Kuberenets clusters to Azure Arc is only possible throgh the Azure CLI and the Terraform null resource. Here is an example of how to connect a K3D cluster to Azure Arc. You can view the setup for both clusters under [aks](../aks.tf) and [k3d](../k3d.tf)

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
