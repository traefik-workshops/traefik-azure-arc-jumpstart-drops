# Secure Traefik Airlines application using Let's Encrypt and Traefik automated certificate management

This module demonstrates how to enable automatic HTTPS for your services using Traefik's Let's Encrypt integration.

## TLS Configuration

The deployment configures Traefik with:

- **Automatic Certificate Management**: Using Let's Encrypt
- **HTTP Challenge**: For domain ownership verification
- **Wildcard Domains**: Using sslip.io for easy testing
- **Zero-touch Configuration**: Automatic certificate generation and renewal

## Important Notes

- Only the AKS cluster supports Let's Encrypt integration as it requires a public IP
- k3d cluster will not be able to complete the ACME challenge due to lack of public IP
- Certificates are automatically stored and renewed by Traefik

> **Note:** Please refer to the [README](../README.md) for a list of requirements.

## Deployment
* Install Traefik Airlines k8s application
  ```shell
  terraform init
  terraform apply -var="azure_subscription_id=$(az account show --query id -o tsv)" -var-file="3-tls/terraform.tfvars"
  ```

* Verify that Traefik Airlines applications are expose through Traefik through the AKS cluster. k3d cluster will not be able to support the acme challenge because it does not have a public IP.

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
