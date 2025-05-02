# Configure the Azure provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create an Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create an App Service Plan (Linux)
resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# Deploy a Linux Web App for the Python application
resource "azurerm_linux_web_app" "python_app" {
  name                = var.python_app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      # Set the Docker image from ACR
      docker_image_name = "${azurerm_container_registry.acr.login_server}/${var.python_image_name}:latest"
    }

    # Use managed identity to pull image from ACR
    container_registry_use_managed_identity = true
  }

  # Set environment variable for the app port
  app_settings = {
    "WEBSITES_PORT" = var.python_port
  }
}

# Deploy a Linux Web App for the Spring Boot application
resource "azurerm_linux_web_app" "spring_app" {
  name                = var.spring_app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      # Set the Docker image from ACR
      docker_image_name = "${azurerm_container_registry.acr.login_server}/${var.spring_image_name}:latest"
    }

    # Use managed identity to pull image from ACR
    container_registry_use_managed_identity = true
  }

  # Set environment variable for the app port
  app_settings = {
    "WEBSITES_PORT" = var.spring_port
  }
}

# Grant AcrPull role to the Python app's managed identity
resource "azurerm_role_assignment" "acr_pull_python" {
  principal_id         = azurerm_linux_web_app.python_app.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# Grant AcrPull role to the Spring app's managed identity
resource "azurerm_role_assignment" "acr_pull_spring" {
  principal_id         = azurerm_linux_web_app.spring_app.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}