# Deploy k8s applications to multiple Arc-enabled Kubernetes clusters using FluxCD and expose them using Traefik

The following Azure Arc Jumpstart Drop demonstrates how to deploy a k8s application to multiple Arc-enabled Kubernetes clusters using FluxCD and expose them using Traefik.

  > **Note:** Please refer to the [README](../README.md) for a list of requirements.

  > **Note:** Please refer to the [0-clusters](../0-clusters/README.md) to view the Azure Arc-enabled Kubernetes clusters that will be deployed.

  > **Note:** Please refer to the [1-traefik](../1-traefik/README.md) to view the Traefik for Azure Arc marketplace application that will be deployed.

  > **Note:** Please refer to the [2-routing](../2-routing/README.md) to view the k8s application deployed using FluxCD.

## Deployment
* Install Traefik Airlines k8s application
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="3-tls/terraform.tfvars"
  ```

* Verify that Traefik Airlines applications are expose through Traefik through the aks cluster. k3d cluster will not be able to support the acme challenge because it does not have a public IP.

  Customers service:
  ```shell
  curl https://customers.traefik-airlines.$(terraform output -raw aks_traefik_ip).sslip.io
  ```

  Employees service:
  ```shell
  curl https://employees.traefik-airlines.$(terraform output -raw aks_traefik_ip).sslip.io
  ```

  Flights service:
  ```shell
  curl https://flights.traefik-airlines.$(terraform output -raw aks_traefik_ip).sslip.io
  ```

  Tickets service:
  ```shell
  curl https://tickets.traefik-airlines.$(terraform output -raw aks_traefik_ip).sslip.io
  ```
