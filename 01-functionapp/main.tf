# Configure the AzureRM provider
provider "azurerm" {
  # Enables the default features of the provider
  features {}
}

# Data source to fetch details of the primary subscription
data "azurerm_subscription" "primary" {}

# Data source to fetch the details of the current Azure client
data "azurerm_client_config" "current" {}

# Define a resource group for all resources in this setup
resource "azurerm_resource_group" "flasky_resource_group" {
  name     = "flasky-resource-group" # Name of the resource group
  location = "Central US"           # Region where resources will be deployed
}
