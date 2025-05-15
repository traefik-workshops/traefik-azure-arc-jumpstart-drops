variable "enable_aks" {
  type        = bool
  description = "Enable AKS cluster"
  default     = true
}

variable "enable_k3d" {
  type        = bool
  description = "Enable k3d cluster"
  default     = true
}

variable "enable_traefik" {
  type        = bool
  description = "Enable Traefik"
  default     = true
}

variable "enable_traefik_airlines" {
  type        = bool
  description = "Enable Traefik Airlines"
  default     = true
}

variable "enable_traefik_airlines_tls" {
  type        = bool
  description = "Enable Traefik Airlines TLS"
  default     = true
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID to use for the deployment"
  default     = ""
  sensitive   = true
}

variable "azure_location" {
  type        = string
  description = "Azure location to use for the deployment"
  default     = "eastus"
}

variable "aks_version" {
  type        = string
  description = "AKS version to use for the deployment"
  default     = "1.32.2"
}

variable "aks_cluster_machine_type" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "Standard_DS2_v2"
}

variable "aks_cluster_node_count" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 2
}
