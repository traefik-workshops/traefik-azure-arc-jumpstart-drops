# Deploy k8s applications to multiple Arc-enabled Kubernetes clusters using FluxCD and expose them using Traefik

The following Azure Arc Jumpstart Drop demonstrates how to deploy a k8s application to multiple Arc-enabled Kubernetes clusters using FluxCD and expose them using Traefik.

  > **Note:** Please refer to the [README](../README.md) for a list of requirements.
  > **Note:** Please refer to the [0-clusters](../0-clusters/README.md) to view the Azure Arc-enabled Kubernetes clusters that will be deployed.
  > **Note:** Please refer to the [1-traefik](../1-traefik/README.md) to view the Traefik for Azure Arc marketplace application that will be deployed.

## Deployment
* Install Traefik Airlines k8s application
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="2-routing/terraform.tfvars"
  ```

* Verify that Traefik Airlines applications are expose through Traefik through the k3d cluster. You can choose either of the clusters to test against.

  K3D url:
  ```shell
  url="localhost:8000"
  ```

  AKS url:
  ```shell
  url=$(kubectl get svc --context $(terraform output -raw aks_cluster_name) --namespace traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  ```

  Customers service:
  ```shell
  curl http://$url -H "Host: customers.traefik-airlines"
  ```

  Employees service:
  ```shell
  curl http://$url -H "Host: employees.traefik-airlines"
  ```

  Flights service:
  ```shell
  curl http://$url -H "Host: flights.traefik-airlines"
  ```

  Tickets service:
  ```shell
  curl http://$url -H "Host: tickets.traefik-airlines"
  ```
