#!/bin/bash

branch_params_json=$(cat <<EOF
    {
        "required_status_checks": {
            "strict": true,
            "contexts": [
            "continuous-integration/travis-ci"
            ]
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "required_approving_review_count": 1
        },
        "restrictions": null
    }
EOF
)

function init() {
    # Install jq
    #sudo apt-get install jq

    cp -r * $HOME/
    cd $HOME

    echo "CHECKING MANIFEST REPO URL"
    if [[ -z "$MANIFEST_REPO" ]]; then
        echo 'MANIFEST REPO URL not specified in variable $MANIFEST_REPO'
        exit 1
    fi

    echo "VERIFYING PERSONAL ACCESS TOKEN"
    if [[ -z "$ACCESS_TOKEN_SECRET" ]]; then
        echo "Please set env var ACCESS_TOKEN_SECRET for git host: $GIT_HOST"
        exit 1
    fi
}

# Check for branch policies
function branch_policy_verification() {
    echo "BRANCH PROTECTION VERFICATION"

    verification=$(curl -s --user "yradsmikham:$ACCESS_TOKEN_SECRET" \
    -H "Accept: application/vnd.github.luke-cage-preview+json" \
    -H "Content-Type: application/json" \
    -X GET https://api.github.com/repos/yradsmikham/walmart-hld/branches/master/protection)

    update_branch_policies=$(curl -s --user "yradsmikham:$ACCESS_TOKEN_SECRET" \
    -H "Accept: application/vnd.github.luke-cage-preview+json" \
    -H "Content-Type: application/json" \
    -X PUT -d $branch_params_json https://api.github.com/repos/yradsmikham/walmart-hld/branches/master/protection)

    echo $verification | jq '.message'

    if [[ "echo $verification | jq '.message'" == "Branch not protected" ]]; then
        echo "Branch is not protected. Will attempt to update branch policies..."
        update_branch_policies
    elif [ -z "echo $verification | jq '.message'" ]; then
        echo "Checking if branch protection is enabled"
        if [[ "echo $verification | jq '.required_status_checks.strict'" == "true" ]]; then  
            echo "Branch policy is ENABLED."
        else
            echo "An error has occurred"
            set -e
        fi
    else
        echo "An error has occurred."
        set -e
    fi
}

# Initialize Helm
function helm_init() {
    echo "RUN HELM INIT"
    helm init
    echo "HELM ADD INCUBATOR"
    if [ -z "$HELM_CHART_REPO" ] || [ -z "$HELM_CHART_REPO_URL" ];
    then
        echo "Using DEFAULT helm repo..."
        helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
    else
        echo "Using DEFINED helm repo..."
        helm repo add $HELM_CHART_REPO $HELM_CHART_REPO_URL
    fi
}

# Obtain version for Fabrikate
# If the version number is not provided, then download the latest
function get_fab_version() {
    if [ -z "$VERSION" ]
    then
        VERSIONS=$(curl -s https://api.github.com/repos/Microsoft/fabrikate/tags)
        LATEST_RELEASE=$(echo $VERSIONS | grep "name" | head -1)
        VERSION_TO_DOWNLOAD=`echo "$LATEST_RELEASE" | cut -d'"' -f 4`
    else
        echo "Fabrikate Version: $VERSION"
        VERSION_TO_DOWNLOAD=$VERSION
    fi
}

# Obtain OS to download the appropriate version of Fabrikate
function get_os() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        eval "$1='linux'"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        eval "$1='darwin'"
    elif [[ "$OSTYPE" == "msys" ]]; then
        eval "$1='windows'"
    else
        eval "$1='linux'"
    fi
}

# Download Fabrikate
function download_fab() {
    echo "DOWNLOADING FABRIKATE"
    echo "Latest Fabrikate Version: $VERSION_TO_DOWNLOAD"
    os=''
    get_os os
    fab_wget=$(wget -SO- "https://github.com/Microsoft/fabrikate/releases/download/$VERSION_TO_DOWNLOAD/fab-v$VERSION_TO_DOWNLOAD-$os-amd64.zip" 2>&1 | egrep -i "302")
    if [[ $fab_wget == *"302 Found"* ]]; then
       echo "Fabrikate $VERSION_TO_DOWNLOAD downloaded successfully."
    else
        echo "There was an error when downloading Fabrikate. Please check version number and try again."
    fi
    wget "https://github.com/Microsoft/fabrikate/releases/download/$VERSION_TO_DOWNLOAD/fab-v$VERSION_TO_DOWNLOAD-$os-amd64.zip"
    unzip fab-v$VERSION_TO_DOWNLOAD-$os-amd64.zip -d fab
}

# Install Fabrikate
function install_fab() {
    # Run this command to make script exit on any failure
    #set -e
    export PATH=$PATH:$HOME/fab
    fab install --verbose
    helm dependency update /home/vsts/infra/components/fabrikate-jaeger/helm_repos/jaeger/incubator/jaeger
    helm init
    echo "FAB INSTALL COMPLETED"
}

# Run fab generate
function fab_generate() {
    fab generate prod --no-validation
    echo "FAB GENERATE COMPLETED"
    
    set +e

    # If generated folder is empty, quit
    # In the case that all components are removed from the source hld, 
    # generated folder should still not be empty
    if find "$HOME/generated" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        echo "Manifest files have been generated."
    else
        echo "Manifest files could not be generated, quitting..."
        exit 1
    fi  
}

# Authenticate with Git
function git_connect() {
    cd $HOME
    # Remove http(s):// protocol from URL so we can insert PA token
    repo_url=$MANIFEST_REPO
    repo_url="${repo_url#http://}"
    repo_url="${repo_url#https://}"
    echo "GIT CLONE: https://automated:$ACCESS_TOKEN_SECRET@$repo_url"

    git clone https://automated:$ACCESS_TOKEN_SECRET@$repo_url
    repo_url=$MANIFEST_REPO
    repo=${repo_url##*/}

    # Extract repo name from url
    repo_name=${repo%.*}
    cd $repo_name
}

# Git commit
function git_commit() {
    echo "GIT CHECKOUT"
    git checkout master
    echo "GIT STATUS"
    git status
    echo "COPY YAML FILES TO REPO DIRECTORY..."
    rm -rf prod/
    cp -r $HOME/generated/* .
    echo "GIT ADD"
    git add *

    #Set git identity 
    git config user.email "admin@azuredevops.com"
    git config user.name "Automated Account"

    echo "GIT COMMIT"
    git commit -m "Updated k8s manifest files post commit: $COMMIT_MESSAGE"
    retVal=$? && [ $retVal -ne 0 ] && exit $retVal
    echo "GIT STATUS" 
    git status
    echo "GIT PULL" 
    git pull
}

# Perform a Git push
function git_push() {  
    # Remove http(s):// protocol from URL so we can insert PA token
    repo_url=$MANIFEST_REPO
    repo_url="${repo_url#http://}"
    repo_url="${repo_url#https://}"

    echo "GIT PUSH: https://$ACCESS_TOKEN_SECRET@$repo_url"
    git push https://$ACCESS_TOKEN_SECRET@$repo_url
    retVal=$? && [ $retVal -ne 0 ] && exit $retVal
    echo "GIT STATUS"
    git status
}

function unit_test() {
    echo "Sourcing for unit test..."
}

function verify() {
    echo "Starting verification"
    init
    #branch_policy_verification
    #helm_init
    get_fab_version
    download_fab
    install_fab
    fab_generate
}

# Run functions
function verify_and_push() {
    verify
    echo "Verification complete, push to yaml repo"
    git_connect
    git_commit
    git_push
}

echo "argument is ${1}"
if [[ "$VERIFY_ONLY" == "1" ]]; then
    verify
elif [ "${1}" == "--source-only" ]; then
    unit_test
else
    verify_and_push
fi
