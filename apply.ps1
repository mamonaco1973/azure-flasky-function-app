
 ./check_env.ps1
 $returnCode = $LASTEXITCODE

# Check if the return code indicates failure
 if ($returnCode -ne 0) {
     Write-Host "ERROR: check_env.ps1 failed with exit code $returnCode. Stopping the script." -ForegroundColor Red
     exit $returnCode
 }

Set-Location -Path "01-functionapp"

# Write-Host "NOTE: Build and deploy the Function App"

terraform init 
terraform apply -auto-approve

# Write-Host "NOTE: Zipping python code into functions.zip"

# Remove-Item -Path "functions.zip" -Force -ErrorAction SilentlyContinue
# Set-Location -Path "functions"

# wsl zip -r ../functions.zip . -x "*/.vscode/*" "*/__pycache__/*"
# Set-Location -Path ..

# Write-Host "NOTE: Publishing latest code using the AZ CLI"

#$FunctionAppName = az functionapp list --resource-group flasky-resource-group --query "[?starts_with(name, 'flasky-')].name" --output tsv
#az functionapp deployment source config-zip --name $FunctionAppName --resource-group flasky-resource-group --src .\functions.zip  --build-remote true 

Set-Location -Path ..



