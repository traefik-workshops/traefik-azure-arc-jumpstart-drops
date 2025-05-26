variable "googleProjectId" {
  type        = string
  description = "Google project ID to use for the deployment"
}

variable "gkeVersion" {
  type        = string
  description = "GKE version to use for the deployment"
  default     = ""
}

variable "gkeClusterLocation" {
  type        = string
  description = "GKE cluster location to use for the deployment"
  default     = "us-west3-a"
}

variable "gkeClusterMachineType" {
  type        = string
  description = "Machine type to use for the deployment"
  default     = "c4-standard-2"
}

variable "gkeClusterNodeCount" {
  type        = number
  description = "Number of nodes to use for the deployment"
  default     = 2
}
