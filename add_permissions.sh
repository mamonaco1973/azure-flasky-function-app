#!/bin/bash

# Define the resource group
RESOURCE_GROUP="flasky-resource-group"

# Fetch the principal UUID of the current Azure CLI connection

# Log in using the service principal and capture the JSON response
echo "NOTE: Logging into Azure using Service Principal..."
LOGIN_RESPONSE=$(az login --service-principal --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" -o json)

if [[ $? -ne 0 ]]; then
    echo "ERROR: Azure login failed. Please check your service principal credentials."
    exit 1
fi

# Extract the Principal ID (user.name) from the JSON response
PRINCIPAL_UUID=$( az ad sp show --id $ARM_CLIENT_ID --query "id" -o tsv)

# Get the Cosmos DB account in the resource group
#echo "NOTE: Fetching Cosmos DB account in resource group: $RESOURCE_GROUP..."

COSMOS_ACCOUNT=$(az cosmosdb list --resource-group "$RESOURCE_GROUP" --query "[?starts_with(name, 'candidates')].name | [0]" -o tsv)

# Check if an account is found
if [[ -z "$COSMOS_ACCOUNT" ]]; then
    echo "ERROR: No Cosmos DB account found in resource group '$RESOURCE_GROUP' starting with 'candidates'."   
    exit 1 
fi

# Fetch the custom role definition ID
COSMOS_ROLE_NAME="CustomCosmoDBRole"
#echo "NOTE: Fetching custom role definition ID for role '$COSMOS_ROLE_NAME' in Cosmos DB account '$COSMOS_ACCOUNT'..."

ROLE_DEFINITION_LIST=$(az cosmosdb sql role definition list --account-name "$COSMOS_ACCOUNT" --resource-group "$RESOURCE_GROUP" -o json)
CUSTOM_ROLE=$(echo "$ROLE_DEFINITION_LIST" | jq -r ".[] | select(.roleName == \"$COSMOS_ROLE_NAME\") | .id")

if [[ -z "$CUSTOM_ROLE" ]]; then
    echo "ERROR: Custom role '$COSMOS_ROLE_NAME' not found in the Cosmos DB account. Check if it has been created."
    exit 1
fi

# Define the scope for the role assignment
SCOPE="/subscriptions/$(az account show --query 'id' -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DocumentDB/databaseAccounts/$COSMOS_ACCOUNT"

# Create the role assignment
echo "NOTE: Creating role assignment for principal '$PRINCIPAL_UUID' with role '$CUSTOM_ROLE' at scope '$SCOPE'..."
az cosmosdb sql role assignment create \
    --account-name "$COSMOS_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --scope "$SCOPE" \
    --principal-id "$PRINCIPAL_UUID" \
    --role-definition-id "$CUSTOM_ROLE"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Role assignment created successfully."
else
    echo "ERROR: Failed to create role assignment."
    exit 1
fi

echo "NOTE: Local debugging of function app is now enabled."

