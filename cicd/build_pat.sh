cd /home/vsts/work/1/s/

# If the version number is not provided, then download the latest
if [ -z "$VERSION" ]
then
    VERSIONS=$(curl -s https://api.github.com/repos/Microsoft/fabrikate/tags)
    LATEST_RELEASE=$(echo $VERSIONS | grep "name" | head -1)
    LATEST_VERSION=`echo "$LATEST_RELEASE" | cut -d'"' -f 4`
else
    echo "Fabrikate Version: $VERSION"
fi

echo "Downloading Fabrikate..."
echo "Latest Fabrikate Version: $LATEST_VERSION"
wget "https://github.com/Microsoft/fabrikate/releases/download/$LATEST_VERSION/fab-v$LATEST_VERSION-linux-amd64.zip"
unzip fab-v$LATEST_VERSION-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab
fab install

fab generate prod
echo "FAB GENERATE PROD COMPLETED"
ls -a

cd /home/vsts/work/1/s/
echo "GIT CLONE"
git clone $AKS_MANIFEST_REPO_URL # Example: https://github.com/yradsmikham/walmart-k8s.git
git clone https://github.com/yradsmikham/walmart-k8s.git
url = https://github.com/yradsmikham/walmart-k8s.git
basename=$(basename $url)
repo_name=${basename%.*}
cd repo_name

echo "GIT CHECKOUT"
git checkout master
echo "GIT STATUS"
git status
echo "Copy yaml files to repo directory..."
rm -rf prod/
cp -r /home/vsts/work/1/s/generated/* .
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
echo "GIT PULL" 
git pull
echo "GIT PUSH"
git push https://$ACCESS_TOKEN@github.com/yradsmikham/walmart-k8s.git
echo "GIT STATUS"
git status
