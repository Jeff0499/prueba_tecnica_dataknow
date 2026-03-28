# Grupo de recursos
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Cuenta de almacenamiento (ADLS Gen2)
resource "azurerm_storage_account" "datalake" {
  name = lower(replace("st${var.resource_group_name}${var.environment}", "-", ""))
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true   # ADLS Gen2
  tags                     = var.tags
}

# Contenedores Bronze, Silver, Gold
resource "azurerm_storage_container" "bronze" {
  name                 = "bronze"
  storage_account_name = azurerm_storage_account.datalake.name
}
resource "azurerm_storage_container" "silver" {
  name                 = "silver"
  storage_account_name = azurerm_storage_account.datalake.name
}
resource "azurerm_storage_container" "gold" {
  name                 = "gold"
  storage_account_name = azurerm_storage_account.datalake.name
}

# Azure Data Factory
resource "azurerm_data_factory" "main" {
  name                = "adf-${var.resource_group_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Azure Databricks Workspace (necesario para transformaciones Silver/Gold)
resource "azurerm_databricks_workspace" "main" {
  name                = "dbw-${var.resource_group_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"   # premium para usar clústeres con autenticación de Azure AD
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.resource_group_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.resource_group_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Action Group para alertas (correo electrónico)
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.resource_group_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alert"
  email_receiver {
    name          = "team"
    email_address = "jeferson.lopez@example.com"   # CAMBIAR por tu correo
  }
}

# Data source para obtener información del cliente actual
data "azurerm_client_config" "current" {}