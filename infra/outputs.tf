output "app_endpoint" {
  value = "https://${azurerm_linux_function_app.infrafly_app.default_hostname}"
}
