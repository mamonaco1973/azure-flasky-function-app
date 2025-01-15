resource "azurerm_service_plan" "flasky_asp" {
  name                = "flasky-asp-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  location            = azurerm_resource_group.flasky_resource_group.location
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
  os_type             = "Linux"
  sku_name            = "Y1" 
}

resource "azurerm_application_insights" "flasky_app_insights" {
  name                = "flasky-ai-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  location            = azurerm_resource_group.flasky_resource_group.location
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "flasky_function_app" {
  name                       = "flasky-app-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  location                   = azurerm_resource_group.flasky_resource_group.location
  resource_group_name        = azurerm_resource_group.flasky_resource_group.name
  service_plan_id            = azurerm_service_plan.flasky_asp.id
  storage_account_name       = azurerm_storage_account.flasky_storage.name
  storage_account_access_key = azurerm_storage_account.flasky_storage.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
    cors {
      allowed_origins = ["*"]
    }
    always_on = false
  }

  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION"    = "~4"
    "AzureWebJobsStorage"            = azurerm_storage_account.flasky_storage.primary_connection_string
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "PYTHON_VERSION"                 = "3.11"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.flasky_app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.flasky_app_insights.connection_string
    "COSMOS_ENDPOINT"                = azurerm_cosmosdb_account.candidate_account.endpoint
    "COSMOS_DATABASE_NAME"           = "CandidateDatabase"
    "COSMOS_CONTAINER_NAME"          = "Candidates"
  }

  https_only = true
}

# Define a custom Cosmos DB role
resource "azurerm_cosmosdb_sql_role_definition" "custom_cosmos_role" {
  name                = "CustomCosmoDBRole"                               # Role name
  resource_group_name = azurerm_resource_group.flasky_resource_group.name # Resource group name
  account_name        = azurerm_cosmosdb_account.candidate_account.name   # Cosmos DB account name
  type                = "CustomRole"                                      # Role type
  assignable_scopes   = [azurerm_cosmosdb_account.candidate_account.id]   # Assignable scopes

  permissions {
    data_actions = [ # Data actions allowed
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_role_assignment" {
  principal_id        = azurerm_linux_function_app.flasky_function_app.identity[0].principal_id
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id
  scope               = azurerm_cosmosdb_account.candidate_account.id
  account_name        = azurerm_cosmosdb_account.candidate_account.name
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
}
