# Storage account used by the function app for internal state (e.g., triggers, logs).
# shared_access_key_enabled = false enforces Azure AD auth only (no storage keys).
resource "azurerm_storage_account" "infrafly_blob_storage" {
  name                          = "${var.resource_prefix}infraflyblobstorage"
  resource_group_name           = azurerm_resource_group.infrafly_rg.name
  location                      = azurerm_resource_group.infrafly_rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  shared_access_key_enabled     = false
}

# App Service plan that hosts the function app (Linux, S1 tier).
resource "azurerm_service_plan" "infrafly_service_plan" {
  name                = "${var.resource_prefix}-infrafly-service-plan"
  location            = azurerm_resource_group.infrafly_rg.location
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# Application Insights for monitoring and diagnostics.
resource "azurerm_application_insights" "infrafly_app_insights" {
  name                = "${var.resource_prefix}-appinsights-infrafly-func-app"
  location            = azurerm_resource_group.infrafly_rg.location
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  application_type    = "other"
}

# Linux Function App (Python 3.12).
# Uses managed identity to access its backing storage account (no access keys).
resource "azurerm_linux_function_app" "infrafly_app" {
  name                                           = "${var.resource_prefix}-infrafly-func-app"
  location                                       = azurerm_resource_group.infrafly_rg.location
  resource_group_name                            = azurerm_resource_group.infrafly_rg.name
  storage_account_name                           = azurerm_storage_account.infrafly_blob_storage.name
  storage_uses_managed_identity                  = true
  service_plan_id                                = azurerm_service_plan.infrafly_service_plan.id
  ftp_publish_basic_authentication_enabled       = true
  webdeploy_publish_basic_authentication_enabled = true

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.infrafly_app_insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.infrafly_app_insights.connection_string

    # Event Hub trigger connection (managed identity — no connection string needed).
    EventHubConnection__fullyQualifiedNamespace = "${azurerm_eventhub_namespace.infrafly_eventhub_ns.name}.servicebus.windows.net"
    EVENT_HUB_NAME                              = azurerm_eventhub.infrafly_eventhub.name

    # Cosmos DB connection (managed identity).
    COSMOSDB_ENDPOINT = azurerm_cosmosdb_account.infrafly_cosmosdb.endpoint
  }
  site_config {
    always_on = true
    application_stack {
      python_version = "3.12"
    }
    application_insights_connection_string = azurerm_application_insights.infrafly_app_insights.connection_string
    application_insights_key               = azurerm_application_insights.infrafly_app_insights.instrumentation_key
  }
  identity {
    type = "SystemAssigned"
  }
}

# Grant the function app's managed identity blob data owner access to its storage account.
resource "azurerm_role_assignment" "infrafly_app_blob_data_owner" {
  scope                = azurerm_storage_account.infrafly_blob_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.infrafly_app.identity[0].principal_id
}
