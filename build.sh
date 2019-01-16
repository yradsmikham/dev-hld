#!/bin/bash

# Create .ssh directory
echo "mkdir ~/.ssh/"
mkdir ~/.ssh/
#chmod -R 777 ~/.ssh/
touch ~/.ssh/known_hosts

echo "listing contents in .ssh directory..."
ls ~/.ssh/

# Add GitHub.com to known_hosts file
echo "Adding Github.com to known_hosts file..."
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
echo "Printing content of known_hosts file..."
cat ~/.ssh/known_hosts

# Login to AZ
echo "AZ Login"
az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT

# Download private and Public key from KeyVault
echo "Accessing KeyVault..."
az keyvault secret download --name idarsa --vault-name yradsmik-walmart-k8s --file ~/.ssh/id_rsa
az keyvault secret download --name idarsapub --vault-name yradsmik-walmart-k8s --file ~/.ssh/id_rsa.pub

#Add the copied keys by using ssh-add. We need to start the ssh-agent first
ls ~/.ssh/
eval `ssh-agent -s`
ssh-add

# Tighten security for private key
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub

# Fabrikate
echo "Downloading Fabrikate..."
wget "https://github.com/Microsoft/fabrikate/releases/download/0.1.2/fab-v0.1.2-linux-amd64.zip"
unzip fab-v0.1.2-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab

git clone https://github.com/Microsoft/fabrikate
cd fabrikate/examples/getting-started
fab install
fab generate prod

cd /home/vsts/work/1/s/

# Git

echo "Cloning Git Repo..."
git clone git@github.com:yradsmikham/walmart-k8s
cd walmart-k8s
echo "GIT CHECKOUT MASTER"
git checkout master
echo "GIT STATUS"
git status
echo "Copy yaml files to repo directory..."
cp -r /home/vsts/work/1/s/fabrikate/examples/getting-started/generated/* /home/vsts/work/1/s/walmart-k8s
ls /home/vsts/work/1/s/walmart-k8s
echo "GIT ADD"
git add *

#Set git identity 
git config user.email "admin@azuredevops.com"
git config user.name "Automated Account"

echo "GIT COMMIT"
git commit -m "Updated k8s manifest files"
echo "GIT STATUS" 
git status
echo "GIT PUSH"
git push origin
echo "GIT STATUS"
git status
