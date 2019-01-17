# Configure the Azure Provider
provider "azurerm" {
  version = "=1.21.0"
}

# Create a resource group
resource "azurerm_resource_group" "yradsmik-walmart-resource-group" {
  name     = "${var.project_name}-${var.environment}"
  location = "West US"
}

# Create KeyVault
resource "azurerm_key_vault" "yradsmik-walmart-keyvault" {
  name                        = "${var.project_name}-${var.environment}"
  location                    = "${azurerm_resource_group.yradsmik-walmart-resource-group.location}"
  resource_group_name         = "${azurerm_resource_group.yradsmik-walmart-resource-group.name}"
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.tenant_id}"

  sku {
    name = "standard"
  }

  access_policy {
    tenant_id = "${var.tenant_id}"
    object_id = "${var.object_id}"

    key_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "recover",
      "backup",
      "restore"
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "recover",
      "backup",
      "restore"
    ]
  }

  tags {
    environment = "${var.environment}"
  }
}

# Generate SSH-Key (Shell Script)
resource "null_resource" "generate-sshkeys" {
    depends_on = ["azurerm_key_vault.yradsmik-walmart-keyvault"]
  provisioner "local-exec" {
    command = <<EOT
    az login --service-principal -u ${var.app_id} -p ${var.pass} --tenant ${var.tenant_id}
    ssh-keygen -t rsa -N '' -f sshkey
    TOKEN="${var.pat}"
    KEY=$( cat sshkey.pub )
    TITLE="yradsmik-walmart-dev"
    JSON=$( printf '{"title": "%s", "key": "%s"}' "$TITLE" "$KEY" )
    curl -s -d "$JSON" "https://api.github.com/user/keys?access_token=$TOKEN"
    az keyvault secret set --name sshkey --vault-name "${var.project_name}-${var.environment}" --file sshkey
    az keyvault secret set --name sshkeypub --vault-name "${var.project_name}-${var.environment}" --file sshkey.pub
    EOT
    }
}
