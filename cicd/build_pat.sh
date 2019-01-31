function copy_files() {
    cd .. && cp -r * $HOME/
    cd $HOME
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

# Download Fabrikate and install
function download_fab() {
    echo "DOWNLOADING FABRIKATE..."
    echo "Latest Fabrikate Version: $VERSION_TO_DOWNLOAD"
    wget "https://github.com/Microsoft/fabrikate/releases/download/$VERSION_TO_DOWNLOAD/fab-v$VERSION_TO_DOWNLOAD-linux-amd64.zip"
    unzip fab-v$VERSION_TO_DOWNLOAD-linux-amd64.zip -d fab
    export PATH=$PATH:$HOME/fab
    fab install
    echo "FAB INSTALL COMPLETED"
}

# Run fab generate
function fab_generate() {
    fab generate prod
    echo "FAB GENERATE COMPLETED"
    ls -a

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
    echo "GIT CLONE"
    git clone https://github.com/$AKS_MANIFEST_REPO.git
    repo_url=https://github.com/$AKS_MANIFEST_REPO.git
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
    ls $HOME/$repo_name
    echo "GIT ADD"
    git add *

    #Set git identity 
    git config user.email "admin@azuredevops.com"
    git config user.name "Automated Account"

    echo "GIT COMMIT"
    git commit -m "Updated k8s manifest files post commit: $COMMIT_MESSAGE"
    echo "GIT STATUS" 
    git status
    echo "GIT PULL" 
    git pull
}

# Perform a Git push
function git_push() {
    echo "GIT PUSH"
    git push https://$ACCESS_TOKEN@github.com/$AKS_MANIFEST_REPO.git
    echo "GIT STATUS"
    git status
}

# Run functions
function main() {
    copy_files
    helm_init
    get_fab_version
    download_fab
    fab_generate
    git_connect
    git_commit
    git_push
}

if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi
