# Define an Azure App Service Plan (Consumption plan)
resource "azurerm_service_plan" "flasky_asp" {
  # Name of the service plan, dynamically appended with the first 8 characters of the subscription ID for uniqueness
  name                = "flasky-asp-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  
  # Location of the service plan, derived from the associated resource group
  location            = azurerm_resource_group.flasky_resource_group.location
  
  # The resource group in which the service plan will reside
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
  
  # OS type for the plan; "Linux" specifies that this plan supports Linux-based applications
  os_type             = "Linux"
  
  # SKU name for the plan; "Y1" represents the consumption-based pricing tier
  sku_name            = "Y1"
}

# Define an Azure Application Insights resource for monitoring
resource "azurerm_application_insights" "flasky_app_insights" {
  # Name of the Application Insights resource, dynamically appended with the first 8 characters of the subscription ID for uniqueness
  name                = "flasky-ai-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  
  # Location of the resource, aligned with the associated resource group
  location            = azurerm_resource_group.flasky_resource_group.location
  
  # The resource group in which the Application Insights resource will reside
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
  
  # Type of the application being monitored; "web" is specified for web applications
  application_type    = "web"
}

# Define an Azure Linux Function App to host serverless Python-based applications
resource "azurerm_linux_function_app" "flasky_function_app" {
  # Name of the Function App, dynamically appended with the first 8 characters of the subscription ID for uniqueness
  name                       = "flasky-app-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  
  # Location of the Function App, derived from the associated resource group
  location                   = azurerm_resource_group.flasky_resource_group.location
  
  # The resource group in which the Function App will reside
  resource_group_name        = azurerm_resource_group.flasky_resource_group.name
  
  # ID of the associated App Service Plan
  service_plan_id            = azurerm_service_plan.flasky_asp.id
  
  # Storage account details for the Function App
  storage_account_name       = azurerm_storage_account.flasky_storage.name
  storage_account_access_key = azurerm_storage_account.flasky_storage.primary_access_key

  # Enable a system-assigned managed identity for the Function App
  identity {
    type = "SystemAssigned"
  }

  # Site configuration settings for the Function App
  site_config {
    # Application stack configuration; Python runtime version is set to 3.11
    application_stack {
      python_version = "3.11"
    }
    # CORS configuration allowing all origins (*)
    cors {
      allowed_origins = ["*"]
    }
    # Disables Always On to save resources
    always_on = false
  }

  # Application settings for the Function App
  app_settings = {
    # Specifies the version of the Functions runtime to use
    "FUNCTIONS_EXTENSION_VERSION"    = "~4"
    # Azure storage connection string for the Function App
    "AzureWebJobsStorage"            = azurerm_storage_account.flasky_storage.primary_connection_string
    # Worker runtime for the Function App; set to Python
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    # Build during deployment
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    # Python version for the application
    "PYTHON_VERSION"                 = "3.11"
    # Application Insights instrumentation key for telemetry
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.flasky_app_insights.instrumentation_key
    # Application Insights connection string for telemetry
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.flasky_app_insights.connection_string
    # Endpoint and configuration for Cosmos DB
    "COSMOS_ENDPOINT"                = azurerm_cosmosdb_account.candidate_account.endpoint
    "COSMOS_DATABASE_NAME"           = "CandidateDatabase"
    "COSMOS_CONTAINER_NAME"          = "Candidates"
  }

  # Enforce HTTPS-only traffic for the Function App
  https_only = true
}

# Define a custom role for Cosmos DB with specific permissions
resource "azurerm_cosmosdb_sql_role_definition" "custom_cosmos_role" {
  # Name of the custom role
  name                = "CustomCosmoDBRole"
  
  # Resource group where the Cosmos DB account resides
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
  
  # Name of the Cosmos DB account to which this role applies
  account_name        = azurerm_cosmosdb_account.candidate_account.name
  
  # Type of role; "CustomRole" indicates a user-defined role
  type                = "CustomRole"
  
  # Scopes to which this role is assignable; limited to the specific Cosmos DB account
  assignable_scopes   = [azurerm_cosmosdb_account.candidate_account.id]

  # Permissions granted to this role
  permissions {
    # Allowed actions on the Cosmos DB account, databases, and items
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata", # Read account metadata
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*", # Full container access
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*" # Full item access
    ]
  }
}

# Assign the custom Cosmos DB role to the Function App's managed identity
resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_role_assignment" {
  # ID of the principal (managed identity) receiving the role assignment
  principal_id        = azurerm_linux_function_app.flasky_function_app.identity[0].principal_id
  
  # ID of the custom role being assigned
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id
  
  # Scope of the role assignment, limited to the specific Cosmos DB account
  scope               = azurerm_cosmosdb_account.candidate_account.id
  
  # Name of the Cosmos DB account
  account_name        = azurerm_cosmosdb_account.candidate_account.name
  
  # Resource group where the Cosmos DB account resides
  resource_group_name = azurerm_resource_group.flasky_resource_group.name
}
