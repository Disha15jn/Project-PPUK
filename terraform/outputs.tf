output "resource_groups" {
  value = {
    core      = data.azurerm_resource_group.core.name
  }
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.resource_id
}

output "sqlmi_network_id" {
  value = data.azurerm_virtual_network.sqlmi_vnet.id
}

output "db_network_id"{
  value = data.azurerm_virtual_network.db_vnet.id
}

output "key_vault_id" {
  value = module.key_vault.resource_id
}

output "sql_managed_instance_id" {
  value = module.sql_mi.resource_id
}

output "data_factory_id" {
  value = {
    for k, v in module.adfs:
    k => v.id
  }
}

output "storage_accounts_ids" {
  value = {
    for k, v in module.stg_accs:
    k => v.id
  }
}

output "purview_account_id" {
  value = one(azurerm_purview_account.this[*].id)
}

output "function_app_id" {
  value = azurerm_linux_function_app.this.id
}

output "aml_id" {
  value =  = module.aml.resource_id
}

output " kv_id" {
  value = module.key_vault.resource_id
}
