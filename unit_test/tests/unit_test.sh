#! /bin/sh

. ../../cicd/build_pat.sh --source-only

oneTimeSetUp() {
    # Configuring environment variables or at least defaults exist
    VERSION=0.2.0
    HELM_CHART_REPO=incubator
    HELM_CHART_REPO_URL=https://kubernetes-charts-incubator.storage.googleapis.com/
    AKS_MANIFEST_REPO=yradsmikham/walmart-k8s
    COMMIT_MESSAGE=Test
    VERSION_TO_DOWNLOAD=$VERSION
    PAT=6b23530756469d3306186dd6827378e9186da10a
}

testHelmInit() {
    result_1=$(helm_init)
    if [[ $result_1 == *"Happy Helming!"*"has been added to your repositories" ]]; then
        assertTrue 0
    else
        assertTrue 1
    fi
}

testFabDownload() {
    ORIGINAL_PWD=$PWD
    cd $HOME

    # Download Fabrikate example 
    git clone https://github.com/Microsoft/fabrikate 

    # If Fab install successfully, then assert Pass (0)
    result_3=$(download_fab)
    if [[ $result_3 == *"downloaded successfully"* ]]; then
        assertTrue 0
    else
        assertTrue 1
    fi
    cd fabrikate/examples/getting-started
    export PATH=$PATH:$HOME/fab
}

testFabInstall() {
    # Install Fab
    cmd="fab install"
    $cmd
    install_status=$?
    if [ $install_status == 0 ]; then
        assertTrue 0
    else    
        assertTrue 1
    fi
}

testFabGenerate() {
    # Checks to see if "generated" folder exists
    cmd="fab generate prod"
    $cmd
    generate_status=$?
    if [ $generate_status == 0 ]; then
        assertTrue 0
    else    
        assertTrue 1
    fi
    cd $ORIGINAL_PWD
}

testGitConnection() {
    # Confirms with Git Checkout and Git Status
    # Extract Git Account
    git_account="$(echo "$AKS_MANIFEST_REPO" | cut -d'/' -f1)"
    echo "GIT CLONE"
    cmd="git clone --progress --verbose https://$git_account:$PAT@github.com/$AKS_MANIFEST_REPO.git"
    $cmd
    git_clone_status=$?
    if [ $git_clone_status == 0 ]; then
        assertTrue 0
    else    
        assertTrue 1
    fi
    # Performs a Git Pull
    echo "GIT PULL" 
    cmd_2="git pull"
    $cmd_2
    git_pull_status=$?
    if [ $git_pull_status == 0 ]; then
        assertTrue 0
    else    
        assertTrue 1
    fi

    # Extract repo name from url
    repo_url=https://github.com/$AKS_MANIFEST_REPO.git
    repo=${repo_url##*/}
    repo_name=${repo%.*}
    cd $repo_name
}

oneTimeTearDown() {
    rm -rf fab*
    rm -rf $HOME/fab*
    rm -rf $ORIGINAL_PWD/$repo_name
}

# Execute shunit2 to run the tests
. ../shunit2/shunit2
