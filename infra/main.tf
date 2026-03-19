# Use the AzureRM provider v4.x.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription id"
  type        = string
}

# Provider configuration.
# storage_use_azuread: authenticate to storage data plane via Azure AD instead of keys.
# prevent_deletion_if_contains_resources: allow destroying RGs that contain
#   auto-created resources not managed by Terraform (e.g., Smart Detector alerts).
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.azure_subscription_id
  storage_use_azuread = true
}

data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

# Resource group for all infrafly resources.
resource "azurerm_resource_group" "infrafly_rg" {
  name     = "${var.resource_prefix}_infrafly_rg"
  location = "West US 2"
}
