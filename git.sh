#!/bin/bash

# Fabrikate
echo "Downloading Fabrikate..."
sudo apt-get update
sudo apt-get install wget
wget "https://github.com/Microsoft/fabrikate/releases/download/0.1.2/fab-v0.1.2-linux-amd64.zip"
unzip fab-v0.1.2-linux-amd-64.zip

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
