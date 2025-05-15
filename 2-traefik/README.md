# Deploy Traefik for Azure Arc from marketplace to Arc-enabled Kubernetes clusters

This module demonstrates how to deploy Traefik Proxy from the Azure Arc Marketplace to Arc-enabled Kubernetes clusters using Terraform and ARM templates.

## Features

- **Marketplace Integration**: Deploy Traefik directly from Azure Arc Marketplace
- **Multi-cluster Support**: Install on both AKS and k3d clusters
- **Dashboard**: Built-in web UI for monitoring and management
- **Automatic Configuration**: Pre-configured for common use cases

## Default Configuration

The Traefik deployment includes:

- Dashboard enabled at `http://dashboard.traefik.localhost:8080` (k3d cluster)
- Default HTTP entrypoint
  - AKS cluster: 80
  - k3d cluster: 8000
- Default HTTPS entrypoint
  - AKS cluster: 443
  - k3d cluster: 8443
- Automatic service discovery

> **Note:** Please refer to the [README](../README.md) for a list of requirements.

## Deployment
* Install [Traefik for Azure Arc](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/GalleryItemDetailsBladeNopdl/id/containous.traefik-on-arc/) application using Terraform
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="2-traefik/terraform.tfvars"
  ```

* Verify that Traefik was installed on both Azure Arc-enabled Kubernetes clusters
  ```shell
  az connectedk8s show --name traefik-arc-aks-demo --resource-group $(terraform output -raw resource_group_name)
  az connectedk8s show --name traefik-arc-k3d-demo --resource-group $(terraform output -raw resource_group_name)
  ```

* You can now view your Traefik dashboard locally.

[http://dashboard.traefik.localhost:8080](http://dashboard.traefik.localhost:8080)

## How to deploy marketplace application using ARM templates with Terraform
To be able to deploy Arc specific marketplace applications with Terraform, you need to use the `azurerm_resource_group_template_deployment` resource. You can simply copy the ARM template from the Azure portal when reviewing the marketplace application install, and paste it into the `template_content` variable in the `azurerm_resource_group_template_deployment` resource. The [Traefik](../traefik.tf) file shows an example of how to deploy the Traefik for Azure Arc marketplace application using ARM templates with Terraform.

------
:arrow_backward: [Clusters](../1-clusters/README.md) | :house: [HOME](../README.md) | [Routing](../3-routing/README.md) :arrow_forward: