variable "enableTraefik" {
  type        = bool
  description = "Enable Traefik"
  default     = true
}

variable "enableTraefikAirlines" {
  type        = bool
  description = "Enable Traefik Airlines"
  default     = true
}

variable "enableTraefikAirlinesTLS" {
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

variable "azureLocation" {
  type        = string
  description = "Azure location to use for the deployment"
  default     = "westus"
}

variable "enableK3D" {
  type        = bool
  description = "Enable k3d cluster"
  default     = true
}

variable "enableAKS" {
  type        = bool
  description = "Enable AKS cluster"
  default     = true
}

variable "aksVersion" {
  type        = string
  description = "AKS version to use for the deployment"
  default     = "1.32.2"
}

variable "aksClusterLocation" {
  type        = string
  description = "AKS cluster location to use for the deployment"
  default     = "westus"
}

variable "aksClusterMachineType" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "Standard_DS2_v2"
}

variable "aksClusterNodeCount" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}

variable "enableEKS" {
  type        = bool
  description = "Enable EKS cluster"
  default     = false
}

variable "eksVersion" {
  type        = string
  description = "EKS version to use for the deployment"
  default     = ""
}

variable "eksClusterLocation" {
  type        = string
  description = "EKS cluster location to use for the deployment"
  default     = "us-west-1"
}

variable "eksClusterMachineType" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "m6a.large"
}

variable "eksClusterNodeCount" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}

variable "enableGKE" {
  type        = bool
  description = "Enable GKE cluster"
  default     = false
}

variable "googleProjectId" {
  type        = string
  description = "Google project ID to use for the deployment"
  default     = ""

  validation {
    condition     = !(var.enableGKE && var.googleProjectId == "")
    error_message = "Google project ID is required when GKE is enabled"
  }
}

variable "gkeVersion" {
  type        = string
  description = "GKE version to use for the deployment"
  default     = ""
}

variable "gkeClusterLocation" {
  type        = string
  description = "GKE cluster location to use for the deployment"
  default     = "us-west3"
}

variable "gkeClusterMachineType" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "c4-standard-2"
}

variable "gkeClusterNodeCount" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 1
}