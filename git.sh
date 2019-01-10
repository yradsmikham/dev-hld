#!/bin/bash

# Fabrikate
echo "Downloading Fabrikate..."
wget "https://github.com/Microsoft/fabrikate/releases/download/0.1.2/fab-v0.1.2-linux-amd64.zip"
unzip fab-v0.1.2-linux-amd64.zip -d fab
export PATH="$PATH:/fab"

git clone https://github.com/Microsoft/fabrikate
cd fabrikate/examples/getting-started
fab install
fab generate prod

# Git
echo "Checking into Github Repo..."
echo "GIT CHECKOUT MASTER"
git checkout master
echo "GIT STATUS"
git status
echo "GIT ADD"
git add *.yml
echo "GIT COMMIT"
git commit -m "Updated k8s manifest files"
echo "GIT STATUS" 
git status
echo "GIT PUSH"
git push origin
echo "GIT STATUS"
git status
