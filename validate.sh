#!/bin/bash

# Set the resource group name
RESOURCE_GROUP_NAME="flasky-resource-group" # Replace with your resource group name

# Retrieve the function app name dynamically
FUNCTION_APP_NAME=$(az functionapp list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?starts_with(name, 'flasky-')].name | [0]" \
    --output tsv)

# Check if FUNCTION_APP_NAME is empty
if [[ -z "$FUNCTION_APP_NAME" ]]; then
    echo "ERROR: No function app found in the resource group '$RESOURCE_GROUP_NAME' with a name starting with 'flasky-'. Exiting script."
    exit 1
fi

# Retrieve the service URL
SERVICE_URL=$(az functionapp show \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "defaultHostName" \
    --output tsv)

# Check if SERVICE_URL is empty
if [[ -z "$SERVICE_URL" ]]; then
    echo "ERROR: Unable to retrieve the service URL for the function app '$FUNCTION_APP_NAME'. Exiting script."
    exit 1
fi

# Add "https://" prefix to construct the full service URL
SERVICE_URL="https://$SERVICE_URL"

# Output notes and test the API Gateway Solution
echo "NOTE: Testing the API Gateway Solution."
echo "NOTE: URL for API Solution is $SERVICE_URL/gtg?details=true"

# Execute the test script with the Service URL
./01-functionapp/test_candidates.py "$SERVICE_URL"

