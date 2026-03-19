# Event Hub namespace — the container for Event Hubs.
# Standard SKU supports up to 20 consumer groups and 1,000 brokered connections.
resource "azurerm_eventhub_namespace" "infrafly_eventhub_ns" {
  name                = "${var.resource_prefix}-infrafly-eventhub-ns"
  location            = azurerm_resource_group.infrafly_rg.location
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  sku                 = "Standard"
}

# Event Hub instance within the namespace.
# partition_count: controls parallelism for consumers (immutable after creation).
# message_retention: how many days events are kept (1–7 for Standard SKU).
resource "azurerm_eventhub" "infrafly_eventhub" {
  name              = "${var.resource_prefix}-infrafly-eventhub"
  namespace_id      = azurerm_eventhub_namespace.infrafly_eventhub_ns.id
  partition_count   = 8
  message_retention = 1
}

# Grant the function app's managed identity permission to receive events.
resource "azurerm_role_assignment" "infrafly_app_eventhub_data_receiver" {
  scope                = azurerm_eventhub_namespace.infrafly_eventhub_ns.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_linux_function_app.infrafly_app.identity[0].principal_id
}
