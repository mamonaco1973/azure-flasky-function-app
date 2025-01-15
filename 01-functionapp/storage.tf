resource "azurerm_storage_account" "flasky_storage" {
  name                     = "flasky${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  resource_group_name      = azurerm_resource_group.flasky_resource_group.name
  location                 = azurerm_resource_group.flasky_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
