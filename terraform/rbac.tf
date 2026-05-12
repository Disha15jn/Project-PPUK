resource "azurerm_role_assignment" "kv_secrets_user_adf_ssis" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.adf_ssis.resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_adf_general" {
  count                = var.enable_native_adf ? 1 : 0
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.adf_general[0].resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_function_app" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_sql_mi" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.sql_mi.identity.principalId
}

resource "azurerm_role_assignment" "adls_blob_contributor_adf_general" {
  count                = var.enable_native_adf ? 1 : 0
  scope                = module.adls.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.adf_general[0].resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "adls_blob_reader_aml" {
  count                = var.enable_analytics ? 1 : 0
  scope                = module.adls.resource_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.azureml[0].system_assigned_mi_principal_id
}

resource "azurerm_role_assignment" "blob_data_contributor_adf_ssis" {
  scope                = module.blob.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.adf_ssis.resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "blob_data_contributor_aml" {
  count                = var.enable_analytics ? 1 : 0
  scope                = module.blob.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azureml[0].system_assigned_mi_principal_id
}

resource "azurerm_role_assignment" "function_storage_blob_owner" {
  scope                = module.function_app_storage.resource_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "purview_data_source_admin_self" {
  count                = var.manage_purview ? 1 : 0
  scope                = azurerm_purview_account.this[0].id
  role_definition_name = "Purview Data Source Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "purview_reader_adf_ssis" {
  count                = var.manage_purview ? 1 : 0
  scope                = azurerm_purview_account.this[0].id
  role_definition_name = "Reader"
  principal_id         = module.adf_ssis.resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "purview_reader_adf_general" {
  count                = var.manage_purview && var.enable_native_adf ? 1 : 0
  scope                = azurerm_purview_account.this[0].id
  role_definition_name = "Reader"
  principal_id         = module.adf_general[0].resource.identity[0].principal_id
}

resource "azurerm_role_assignment" "adls_reader_purview" {
  count                = var.manage_purview ? 1 : 0
  scope                = module.adls.resource_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.this[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "blob_reader_purview" {
  count                = var.manage_purview ? 1 : 0
  scope                = module.blob.resource_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.this[0].identity[0].principal_id
}
