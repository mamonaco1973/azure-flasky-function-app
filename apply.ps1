
 ./check_env.ps1
 $returnCode = $LASTEXITCODE

# Check if the return code indicates failure
 if ($returnCode -ne 0) {
     Write-Host "ERROR: check_env.ps1 failed with exit code $returnCode. Stopping the script." -ForegroundColor Red
     exit $returnCode
 }

Set-Location -Path "01-functionapp"

Write-Host "NOTE: Build and deploy the Function App"

terraform init 
terraform apply -auto-approve

Set-Location -Path ..
Set-Location -Path "02-flasky"

Write-Host "NOTE: Zipping python code into flasky.zip"
Remove-Item -Path "flasky.zip" -Force -ErrorAction SilentlyContinue

# Collect all files and folders to include, excluding the specified items
$files = Get-ChildItem -Recurse | Where-Object {
    $_.FullName -notmatch "(__pycache__|\.vscode|local.settings.json)"
}

# Compress the filtered files into flasky.zip
$files | Compress-Archive -DestinationPath "flasky.zip" -Update

Write-Host "NOTE: Publishing latest code using the AZ CLI"

$FunctionAppName = az functionapp list --resource-group flasky-resource-group --query "[?starts_with(name, 'flasky-')].name" --output tsv
az functionapp deployment source config-zip --name $FunctionAppName --resource-group flasky-resource-group --src .\flasky.zip  --build-remote true 

Set-Location -Path ..

Write-Host "NOTE: Applying role for local debugging."
./add_permissions.ps1

# Validate the solution

Write-Host "NOTE: Validating the solution"

./validate.ps1






