# Deploy k8s applications to multiple Arc-enabled Kubernetes clusters using FluxCD

The following Jumpstart scenario will guide you on how to use Terraform to deploy Azure Arc marketplace application to Arc-enabled Kubernetes clusters.

  > **Note:** Please refer to the [README](../README.md) for a list of requirements.
  > **Note:** Please refer to the [0-clusters](../0-clusters/README.md) to view the Azure Arc-enabled Kubernetes clusters that will be deployed.
  > **Note:** Please refer to the [1-traefik](../1-traefik/README.md) to view the Traefik for Azure Arc marketplace application that will be deployed.

## Deployment
* Install [Traefik for Azure Arc](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc/) application using Terraform
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="2-routing/terraform.tfvars"
  ```

* Verify that Traefik was installed on both Azure Arc-enabled Kubernetes clusters
  ```shell
  az connectedk8s show --name traefik-aks-demo --resource-group traefik-demo
  az connectedk8s show --name traefik-k3d-demo --resource-group traefik-demo
  ```

## How to deploy marketplace application using ARM templates with Terraform
To be able to deploy Arc specific marketplace application with Terraform, you need to use the `azurerm_resource_group_template_deployment` resource. You can simply copy the ARM template from the Azure portal when reviewing the marketplace application install and paste it into the `template_content` variable in the `azurerm_resource_group_template_deployment` resource. The [Traefik](../traefik.tf) file shows an example of how to deploy the Traefik for Azure Arc marketplace application using ARM templates with Terraform.