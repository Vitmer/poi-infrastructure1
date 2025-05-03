# 1. Retrieve the Key Vault
data "azurerm_key_vault" "kv" {
  name                = "dev-kv-WcuDo123"
  resource_group_name = "dev-rg"
}

# 2. Retrieve secrets from Key Vault
data "azurerm_key_vault_secret" "subscription_id" {
  name         = "subscription-id"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "tenant_id" {
  name         = "tenant-id"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "resource_group_name" {
  name         = "resource-group-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "location" {
  name         = "location"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "acr_name" {
  name         = "acr-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "prefix" {
  name         = "prefix"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "python_image_name" {
  name         = "python-image-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "spring_image_name" {
  name         = "spring-image-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "python_app_name" {
  name         = "python-app-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "spring_app_name" {
  name         = "spring-app-name"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "python_port" {
  name         = "python-port"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "spring_port" {
  name         = "spring-port"
  key_vault_id = data.azurerm_key_vault.kv.id
}

# 3. Configure the Azure provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# 4. Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = data.azurerm_key_vault_secret.resource_group_name.value
  location = data.azurerm_key_vault_secret.location.value
}

# 5. Create a storage account
resource "azurerm_storage_account" "tfstate" {
  name                     = "devstorageacctmerenics"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 6. Create a storage container
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# 7. Configure the Terraform backend
terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "devstorageacctmerenics"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# 8. Create an Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = data.azurerm_key_vault_secret.acr_name.value
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 9. Create an App Service Plan (Linux)
resource "azurerm_service_plan" "plan" {
  name                = "${data.azurerm_key_vault_secret.prefix.value}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 10. Deploy a Linux Web App for the Python application
resource "azurerm_linux_web_app" "python_app" {
  name                = data.azurerm_key_vault_secret.python_app_name.value
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image_name = "${azurerm_container_registry.acr.login_server}/${data.azurerm_key_vault_secret.python_image_name.value}:latest"
    }
    container_registry_use_managed_identity = true
  }

  app_settings = {
    "WEBSITES_PORT" = data.azurerm_key_vault_secret.python_port.value
  }
}

# 11. Deploy a Linux Web App for the Spring Boot application
resource "azurerm_linux_web_app" "spring_app" {
  name                = data.azurerm_key_vault_secret.spring_app_name.value
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image_name = "${azurerm_container_registry.acr.login_server}/${data.azurerm_key_vault_secret.spring_image_name.value}:latest"
    }
    container_registry_use_managed_identity = true
  }

  app_settings = {
    "WEBSITES_PORT" = data.azurerm_key_vault_secret.spring_port.value
  }
}

# 12. Grant AcrPull role to the Python app's managed identity
resource "azurerm_role_assignment" "acr_pull_python" {
  principal_id         = azurerm_linux_web_app.python_app.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# 13. Grant AcrPull role to the Spring app's managed identity
resource "azurerm_role_assignment" "acr_pull_spring" {
  principal_id         = azurerm_linux_web_app.spring_app.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

output "python_app_url" {
  description = "URL of the Python Web App"
  value       = azurerm_linux_web_app.python_app.default_site_hostname
}

output "spring_app_url" {
  description = "URL of the Spring Boot Web App"
  value       = azurerm_linux_web_app.spring_app.default_site_hostname
}