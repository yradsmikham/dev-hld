# Create Service Principal
#az ad sp create-for-rbac --role="Owner" --scopes="/subscriptions/$AZURE_SUBSCRIPTION_ID"

# Connect to Subscriptions
az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT

# Create new resource group
az group create -n "yradsmik-walmart" -l "West US"

# Register the Key Vault resource provider
az provider register -n Microsoft.KeyVault

# Create Key Vault 
az keyvault create --name "yradsmikWalmartKeyvault" --resource-group "yradsmik-walmart" --location "West US"
