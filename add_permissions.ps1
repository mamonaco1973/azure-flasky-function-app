# Define the resource group
$ResourceGroup = "flasky-resource-group"

# Fetch the principal UUID of the current Azure CLI connection

# Log in using the service principal and capture the JSON response
Write-Output "NOTE: Logging into Azure using Service Principal..."
$LoginResponse = az login --service-principal --username $env:ARM_CLIENT_ID --password $env:ARM_CLIENT_SECRET --tenant $env:ARM_TENANT_ID --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Azure login failed. Please check your service principal credentials."
    exit 1
} else {
    # Write-Output "NOTE: Azure login successful."
}

# Extract the Principal ID (user.name) from the JSON response
$PrincipalUUID = az ad sp show --id $env:ARM_CLIENT_ID --query "id" --output tsv

# Get the Cosmos DB account in the resource group
# Write-Output "NOTE: Fetching Cosmos DB account in resource group: $ResourceGroup..."

$CosmosAccount = az cosmosdb list --resource-group $ResourceGroup --query "[?starts_with(name, 'candidates')].name | [0]" --output tsv

# Check if an account is found
if ([string]::IsNullOrEmpty($CosmosAccount)) {
    Write-Error "ERROR: No Cosmos DB account found in resource group '$ResourceGroup' starting with 'candidates'."
    exit 1
} else {
    # Write-Output "NOTE: Found Cosmos DB account: $CosmosAccount"
}

# Fetch the custom role definition ID
$CosmosRoleName = "CustomCosmoDBRole"
# Write-Output "NOTE: Fetching custom role definition ID for role '$CosmosRoleName' in Cosmos DB account '$CosmosAccount'..."

$RoleDefinitionList = az cosmosdb sql role definition list --account-name $CosmosAccount --resource-group $ResourceGroup --output json
$CustomRole = ($RoleDefinitionList | ConvertFrom-Json) | Where-Object { $_.roleName -eq $CosmosRoleName } | Select-Object -ExpandProperty id

if ([string]::IsNullOrEmpty($CustomRole)) {
    Write-Error "ERROR: Custom role '$CosmosRoleName' not found in the Cosmos DB account. Check if it has been created."
    exit 1
} else {
    # Write-Output "NOTE: Custom role ID set as environment variable: $CustomRole"
}

# Define the scope for the role assignment
$SubscriptionId = az account show --query 'id' --output tsv
$Scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DocumentDB/databaseAccounts/$CosmosAccount"

# Create the role assignment
Write-Output "NOTE: Creating role assignment for principal '$PrincipalUUID' with role '$CustomRole' at scope '$Scope'..."
az cosmosdb sql role assignment create `
    --account-name $CosmosAccount `
    --resource-group $ResourceGroup `
    --scope $Scope `
    --principal-id $PrincipalUUID `
    --role-definition-id $CustomRole

if ($LASTEXITCODE -eq 0) {
    Write-Output "SUCCESS: Role assignment created successfully."
} else {
    Write-Error "ERROR: Failed to create role assignment."
    exit 1
}

Write-Output "NOTE: Local debugging of function app is now enabled."
