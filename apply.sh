#!/bin/bash

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Navigate to the 01-functionapp directory
cd 01-functionapp 

# Initialize and apply Terraform
terraform init
terraform apply -auto-approve

# Navigate back to the parent directory
cd ..

# Navigate to the 02-flasky directory
cd 02-flasky 

echo "NOTE: Zipping python code into flasky.zip"

# Remove the existing flasky.zip file if it exists
rm -f flasky.zip

# Create a new zip file excluding certain files and directories
zip -r flasky.zip . -x "__pycache__/*" ".vscode/*" "local.settings.json"

# Get the Function App name
FunctionAppName=$(az functionapp list --resource-group flasky-resource-group --query "[?starts_with(name, 'flasky-')].name" --output tsv)

# Publish the latest code using the AZ CLI
az functionapp deployment source config-zip --name "$FunctionAppName" --resource-group flasky-resource-group --src flasky.zip --build-remote true

# Navigate back to the parent directory
cd ..
