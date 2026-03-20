# Azure Cosmos DB account (NoSQL API, serverless).
resource "azurerm_cosmosdb_account" "infrafly_cosmosdb" {
  name                = "${var.resource_prefix}-infrafly-cosmosdb"
  location            = azurerm_resource_group.infrafly_rg.location
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    location          = azurerm_resource_group.infrafly_rg.location
    failover_priority = 0
  }
}

# SQL database inside the Cosmos DB account.
resource "azurerm_cosmosdb_sql_database" "infrafly_cosmosdb_db" {
  name                = "infrafly-db"
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  account_name        = azurerm_cosmosdb_account.infrafly_cosmosdb.name
}

# Container "status" with /id as the partition key.
resource "azurerm_cosmosdb_sql_container" "infrafly_cosmosdb_status" {
  name                = "status"
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  account_name        = azurerm_cosmosdb_account.infrafly_cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.infrafly_cosmosdb_db.name
  partition_key_paths = ["/id"]
}

# Grant the function app's managed identity read/write access to Cosmos DB.
resource "azurerm_cosmosdb_sql_role_assignment" "infrafly_app_cosmosdb_contributor" {
  resource_group_name = azurerm_resource_group.infrafly_rg.name
  account_name        = azurerm_cosmosdb_account.infrafly_cosmosdb.name
  role_definition_id  = "${azurerm_cosmosdb_account.infrafly_cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_linux_function_app.infrafly_app.identity[0].principal_id
  scope               = azurerm_cosmosdb_account.infrafly_cosmosdb.id
}
