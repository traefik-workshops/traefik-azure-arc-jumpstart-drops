This drop demonstrates how to deploy and Arc-enable both AKS and k3d clusters using Terraform. The deployment includes:

- **AKS Cluster**:
  - Single node pool with configurable VM size
  - Exposed ports for ingress (80, 443, 8080)
  - Azure Arc extension installation

- **k3d Cluster**:
  - Local Kubernetes cluster using k3s in Docker
  - Exposed ports for ingress (8000, 8443, 8080)
  - Azure Arc extension installation

> **Note:** Please refer to the [README](https://github.com/traefik-workshops/traefik-azure-arc-jumpstart-drops/blob/main/README.md) for a list of requirements.

## Configuration

The deployment can be customized through the following variables in `terraform.tfvars`:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_aks` | Enable AKS cluster | bool | true | no |
| `enable_k3d` | Enable k3d cluster | bool | true | no |
| `azure_subscription_id` | Azure subscription ID to use for the deployment | string | "" | yes |
| `azure_location` | Azure location to use for the deployment | string | "eastus" | no |
| `aks_version` | AKS version to use for the deployment | string | "1.32.2" | no |
| `aks_cluster_machine_type` | AKS cluster machine type | string | "Standard_DS2_v2" | no |
| `aks_cluster_node_count` | AKS cluster node count | number | 2 | no |

## Deployment
Install AKS and k3d clusters using Terraform:
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="1-clusters/terraform.tfvars"
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