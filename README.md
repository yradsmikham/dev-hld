# walmart-hld
Source Repository for CI/CD Workflow

This repository contains:
- High level deployment description (consumed by [Fabrikate](https://github.com/Microsoft/fabrikate))
- Shell scripts used for automation
- Azure Pipelines yaml file

## Approach

### 1) SSH-key (build_ssh.sh)
- This approach involves deploying an SSH key to the AKS Manifest Git repo prior to running the Azure Pipeline build.
- The SSH key (private and public key) is stored as secrets in Azure Key Vault, and in order to access the the Azure Key Vault, a **Service Pricinpal** in Azure needs to be created and configured beforehand.

### 2) Personal Access Tokens (PAT) (build_pat.sh)
- This approach involves generating a PAT in the AKS Manifest Git repo, and adding the PAT as an encrypted variable in the Azure Pipeline build.

## Configuration

To use an SSH-key, 

1. Generate an SSH Key locally.
`ssh-keygen -t rsa -N "" -f sshkey`

2. In the AKS Manifest Git Repo, go to Settings > SSH and GPG Keys > New SSH Key. Enter a Title, and copy and paste the public key into Key.

3. In terminal, create an Azure Service Principal.
`az ad sp create-for-rbac --role="Owner" --scopes="/subscriptions/$AZURE_SUBSCRIPTION_ID"`

Note: Be sure to save the AppID, Password, Tenant ID.

4. Create new resource group in Azure.
`az group create -n "yradsmik-dev" -l "West US"`

5. Register the Key Vault resource provider
`az provider register -n Microsoft.KeyVault`

6. Create Azure Key Vault.
`az keyvault create --name "yradsmikKV" --resource-group "yradsmik-dev" --location "West US"`

7. In Azure Portal, edit Access Policies for Azure Key Vault to grant Service Principal access.

8. Upload SSH keys as secrets.
`az keyvault secret set --name sshkey --vault-name yradsmikKV --file sshkey`
`az keyvault secret set --name sshkeypub --vault-name yradsmikKV --file sshkey.pub`

9. In Azure Pipelines > Builds > Pipeline Settings> Pipeline Variables, create a variable for `APP_ID`, `PASSWORD`, and `TENANT` using the Service Principal created in step 2.

The azure_pipeline.yml should look like the following:

```
trigger:
- master

pool:
  vmImage: 'Ubuntu-16.04'

steps:
- checkout: self
  persistCredentials: true
  clean: true

- task: ShellScript@2
  inputs:
    scriptPath: cicd/build_ssh.sh
    appId: $APP_ID
    password: $PASSWORD
    tenant: $TENANT

```

To use a PAT,

1. In the AKS Manifest Git Repo, go to Settings > Developer Settings > Personal access tokens > Generate new token. Enter your password, provide a description for the token, and select the appropriate scopes.

2. Copy the PAT.

3. In Azure Pipelines > Builds > Pipeline Settings > Pipeline Variables, paste the PAT as a variable, and encrypt it.

The azure_pipeline.yml should look like the following:

```
trigger:
- master

pool:
  vmImage: 'Ubuntu-16.04'

steps:
- checkout: self
  persistCredentials: true
  clean: true

- task: ShellScript@2
  inputs:
    scriptPath: cicd/build_pat.sh
  env:
   ACCESS_TOKEN: $(ACCESS_TOKEN)

```

## Notes

The example AKS Manifest Git Repo: https://github.com/yradsmikham/walmart-k8s 
