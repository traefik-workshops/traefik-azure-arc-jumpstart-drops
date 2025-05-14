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
