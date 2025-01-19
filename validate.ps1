# Set the resource group name
$ResourceGroupName = "flasky-resource-group"  # Replace with your resource group name

# Retrieve the function app name dynamically
$FunctionAppName = az functionapp list `
    --resource-group $ResourceGroupName `
    --query "[?starts_with(name, 'flasky-')].name | [0]" `
    --output tsv

# Check if $FunctionAppName is empty
if (-not $FunctionAppName) {
    Write-Error "ERROR: No function app found in the resource group '$ResourceGroupName' with a name starting with 'flasky-'. Exiting script."
    exit 1
}

$MasterKey = az functionapp keys list `
  --resource-group $ResourceGroupName `
  --name $FunctionAppName `
  --query "masterKey" -o tsv

Write-Host "NOTE: Key header for functions is 'x-functions-key:$MasterKey'"

# Retrieve the service URL
$SERVICE_URL = az functionapp show `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --query "defaultHostName" `
    --output tsv

# Check if $SERVICE_URL is empty
if (-not $SERVICE_URL) {
    Write-Error "ERROR: Unable to retrieve the service URL for the function app '$FunctionAppName'. Exiting script."
    exit 1
}

# Add "https://" prefix to construct the full service URL
$SERVICE_URL = "https://$SERVICE_URL"

# Output notes and test the API Gateway Solution
Write-Host "NOTE: Testing the API Gateway Solution."
Write-Host "NOTE: URL for API Solution is $SERVICE_URL/gtg?details=true"

# Execute the test script with the Service URL
./01-functionapp/test_candidates.ps1 $SERVICE_URL

