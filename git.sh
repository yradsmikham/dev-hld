#!/bin/bash

# Fabrikate
echo "Downloading Fabrikate..."
wget "https://github.com/Microsoft/fabrikate/releases/download/0.1.2/fab-v0.1.2-linux-amd64.zip"
unzip fab-v0.1.2-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab

git clone https://github.com/Microsoft/fabrikate
cd fabrikate/examples/getting-started
fab install
fab generate prod

cd ~
chmod u+w .
mkdir .ssh
ls
echo "Generating SSH Key..."
ssh-keygen -t rsa
ls
cd .ssh
ls

# SSH Key

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxmugaMunQx/qfDrHUGxI4BizksEl9YyayuBOn+FQNnr2jbz+jaOhYYU2mgMds3gWBmKNVvIpNIuUFm1o78MDKlYh5HkWhXbPiGnarhIlbKhfuX0kIjirbzbryxbVxclKcUvIWlujETCXT6v3PAltknxOLyV1mKnbdLIbMOZw/ssb/2MnOUH06v6hBo+n9/eYVMFDtj1WYNeru9rAVsa9NjZeGwCb2B8QS2X7i82OT8DOaRNvACAuPVOSa61DKinRi2IEFdGY3+5UPkWKrvUnJ0y5DgLVuxlSv9oS/cCB/IhJbHuiwpLBfP1OVjJieMKNCOdAK2MD0azKh3TFH/3suizWa7OecxgRqU844KnIBpxdzfQNTiiR8CWVkQNhHEE23BxLLBVGAuneM/Mqrt1tGRsrztGS2+LfWsorJkDBIGScwkpri7bTaCaGqTA8KuwE//LNk3RiN+c/KMkZwb2uvDi6uCg16u8n+kZnH54VKHmgFJPY2fwPhkOPpKW0PAGVo7pvidW4E00mQ1OlQIxr2jphZ1mUddYajNC6nzcSTGDuL0z04RxNXonKdpKX526jNFFrnMoV+yMOh3nQ/HQvg39v4ZZjgHMRUTF4e1I4UOb/B8Ul69DI37bG0bqS3fbrxQYRPszIZgT32Uqi/dYOvR0WxkkzLhXnPOCqc8S48mQ==

# Git
echo "Cloning Git Repo..."
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
