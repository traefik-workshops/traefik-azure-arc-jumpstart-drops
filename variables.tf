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

variable "azureSubscriptionId" {
  type        = string
  description = "Azure subscription ID to use for the deployment"
  default     = ""
  sensitive   = true
}

variable "azure_location" {
  type        = string
  description = "Azure location to use for the deployment"
  default     = "westus"
}

variable "enable_k3d" {
  type        = bool
  description = "Enable k3d cluster"
  default     = true
}

variable "enable_aks" {
  type        = bool
  description = "Enable AKS cluster"
  default     = true
}

variable "aks_version" {
  type        = string
  description = "AKS version to use for the deployment"
  default     = "1.32.2"
}

variable "aks_cluster_location" {
  type        = string
  description = "AKS cluster location to use for the deployment"
  default     = "westus"
}

variable "aks_cluster_machine_type" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "Standard_DS2_v2"
}

variable "aks_cluster_node_count" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}

variable "enable_eks" {
  type        = bool
  description = "Enable EKS cluster"
  default     = true
}

variable "eks_version" {
  type        = string
  description = "EKS version to use for the deployment"
  default     = ""
}

variable "eks_cluster_location" {
  type        = string
  description = "EKS cluster location to use for the deployment"
  default     = "us-west-1"
}

variable "eks_cluster_machine_type" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "m6a.large"
}

variable "eks_cluster_node_count" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}

variable "enable_gke" {
  type        = bool
  description = "Enable GKE cluster"
  default     = true
}

variable "google_project_id" {
  type        = string
  description = "Google project ID to use for the deployment"
  default     = ""

  validation {
    condition     = !(var.enable_gke && var.google_project_id == "")
    error_message = "Google project ID is required when GKE is enabled"
  }
}

variable "gke_version" {
  type        = string
  description = "GKE version to use for the deployment"
  default     = ""
}

variable "gke_cluster_location" {
  type        = string
  description = "GKE cluster location to use for the deployment"
  default     = "us-west3"
}

variable "gke_cluster_machine_type" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "c4-standard-2"
}

variable "gke_cluster_node_count" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}