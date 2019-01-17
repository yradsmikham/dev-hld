echo "Downloading Fabrikate..."
wget "https://github.com/Microsoft/fabrikate/releases/download/0.1.2/fab-v0.1.2-linux-amd64.zip"
unzip fab-v0.1.2-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab

echo "Running Fabrikate..."
fab install
fab generate prod

git --version
git clone git@github.com:yradsmikham/walmart-k8s
cd walmart-k8s
git checkout master

echo "Copying generated files"
rm -rf prod/
cp -r /home/vsts/work/1/s/generated/* .
echo "git add *"
git add *
echo "setup author info"
git config user.email "me@samiya.ca"
git config user.name "azure-pipelines[bot]"
echo "git commit with message"
git commit --allow-empty -a -m "Updating files after commit"
git remote set-url origin git@github.com:yradsmikham/walmart-k8s.git
echo "git push"
git push https://$ACCESSTOKEN@github.com/yradsmikham/walmart-k8s.git
