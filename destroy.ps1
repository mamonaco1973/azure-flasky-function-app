cd 01-functionapp

az monitor action-group delete --resource-group flasky-resource-group --name "Application Insights Smart Detection"
terraform init
terraform destroy -auto-approve

cd ..
