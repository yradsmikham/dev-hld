# Login to Azure
az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT

# Generate SSH keys for Github
ssh-keygen -t rsa -N "" -f sshkey

# Add ssh-key to github
TOKEN=token
KEY=$( cat sshkey.pub )
TITLE=${KEY/* }
JSON=$( printf '{"title": "%s", "key": "%s"}' "$TITLE" "$KEY" )
curl -s -d "$JSON" "https://api.github.com/user/keys?access_token=$TOKEN"

# Add ssh-key to KeyVault 
az keyvault secret set --name sshkey --vault-name yradsmik-walmart-dev --file sshkey
az keyvault secret set --name sshkeypub --vault-name yradsmik-walmart-dev --file sshkey.pub
