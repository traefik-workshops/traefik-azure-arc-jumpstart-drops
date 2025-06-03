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
  default     = 2
}