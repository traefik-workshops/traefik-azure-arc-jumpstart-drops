terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0"
    }
    k3d = {
      source  = "SneakyBugs/k3d"
      version = "1.0.1"
    }
  }
}