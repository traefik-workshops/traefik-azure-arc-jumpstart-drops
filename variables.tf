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

variable "enableTraefikHubGateway" {
  type        = bool
  description = "Enable Traefik Airlines Hub Gateway"
  default     = false
}

variable "enableTraefikHubManagement" {
  type        = bool
  description = "Enable Traefik Hub Management"
  default     = false
}

variable "traefikHubAKSLicenseKey" {
  type        = string
  description = "Traefik Hub license key for AKS"
  default     = ""

  validation {
    condition     = !(local.enableHub && var.enableAKS && var.traefikHubAKSLicenseKey == "")
    error_message = "Traefik Hub license key is required when Traefik Hub is enabled and AKS is enabled"
  }
}

variable "traefikHubK3DLicenseKey" {
  type        = string
  description = "Traefik Hub license key for K3D"
  default     = ""

  validation {
    condition     = !(local.enableHub && var.enableK3D && var.traefikHubK3DLicenseKey == "")
    error_message = "Traefik Hub license key is required when Traefik Hub is enabled and K3D is enabled"
  }
}

variable "traefikHubEKSLicenseKey" {
  type        = string
  description = "Traefik Hub license key for EKS"
  default     = ""

  validation {
    condition     = !(local.enableHub && var.enableEKS && var.traefikHubEKSLicenseKey == "")
    error_message = "Traefik Hub license key is required when Traefik Hub is enabled and EKS is enabled"
  }
}

variable "traefikHubGKELicenseKey" {
  type        = string
  description = "Traefik Hub license key for GKE"
  default     = ""

  validation {
    condition     = !(local.enableHub && var.enableGKE && var.traefikHubGKELicenseKey == "")
    error_message = "Traefik Hub license key is required when Traefik Hub is enabled and GKE is enabled"
  }
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

variable "enableAKS" {
  type        = bool
  description = "Enable AKS cluster"
  default     = true
}

variable "enableK3D" {
  type        = bool
  description = "Enable k3d cluster"
  default     = false
}

variable "enableEKS" {
  type        = bool
  description = "Enable EKS cluster"
  default     = false
}

variable "enableGKE" {
  type        = bool
  description = "Enable GKE cluster"
  default     = false
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
  default     = 2
}

variable "eksClusterLocation" {
  type        = string
  description = "EKS cluster location to use for the deployment"
  default     = "us-west-1"
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

variable "gkeClusterLocation" {
  type        = string
  description = "GKE cluster location to use for the deployment"
  default     = "us-west3-a"
}
