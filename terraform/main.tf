data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "core" {
  name = local.names.rg_core
}

data "azurerm_resource_group" "aml_rg" {
  name = local.names.rg_aml
}

data "azurerm_virtual_network" "sqlmi_vnet"{
  name                = local.vnet_names.sql_mi
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_virtual_network" "db_vnet"{

  name                = local.vnet_names.databricks
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "sql_mi" {
  name                 = local.subnet_names.sql_mi
  virtual_network_name = data.azurerm_virtual_network.sqlmi_vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = local.subnet_names.private_endpoints
  virtual_network_name = data.azurerm_virtual_network.sqlmi_vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "data_factory" {
  name                 = local.subnet_names.data_factory
  virtual_network_name = data.azurerm_virtual_network.sqlmi_vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "analytics" {
  name                 = local.subnet_names.analytics
  virtual_network_name = data.azurerm_virtual_network.sqlmi_vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "function_app" {
  count                = var.enable_function_app_vnet_integration ? 1 : 0
  name                 = local.subnet_names.function_app
  virtual_network_name = data.azurerm_virtual_network.sqlmi_vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name = local.names.existing_log_workspace
  resource_group_name = data.azurerm_resource_group.core.name
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1" 
  count =  local.names.existing_log_workspace == null ? 1:0

  location                                  = locals.location
  name                                      = local.names.log_analytics
  resource_group_name                       = data.azurerm_resource_group.core.name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = 90
  log_analytics_workspace_sku               = "PerGB2018"
  tags                                      = local.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  location                      = local.location
  name                          = local.names.key_vault
  resource_group_name           = data.azurerm_resource_group.core.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enable_telemetry              = var.enable_telemetry
  public_network_access_enabled = false
  purge_protection_enabled      = true
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  legacy_access_policies_enabled = false
  tags                          = local.tags

  diagnostic_settings = {
    logs = {
      workspace_resource_id = local.names.existing_log_workspace == null ? module.log_analytics_workspace.resource_id : data.azurerm_log_analytics_workspace.log_analytics_workspace.id
    }
  }

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  role_assignments = {
    deployer_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  depends_on = [module.log_analytics]
}

module "stg_accs" {

  for_each = local.storage_accounts 

  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  location                          = local.location
  name                              = each.value.name
  resource_group_name               = data.azurerm_resource_group.core.name
  account_kind                      = "StorageV2"
  account_replication_type          = local.is_prod ? "ZRS" : "LRS"
  account_tier                      = "Standard"
  shared_access_key_enabled         = false
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  is_hns_enabled                    = each.value.is_hns_enabled
  infrastructure_encryption_enabled = true
  enable_telemetry                  = var.enable_telemetry
  tags                              = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings_blob = {
    logs = {
      workspace_resource_id = local.names.existing_log_workspace == null ? module.log_analytics_workspace.resource_id : data.azurerm_log_analytics_workspace.log_analytics_workspace.id
    }
  }
  
  customer_managed_key = 

  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    virtual_network_subnet_ids = toset([data.azurerm_subnet.data_factory.id, data.azurerm_subnet.analytics.id])
  }

  depends_on = [module.log_analytics]
}


resource "azurerm_storage_data_lake_gen2_filesystem" "landing" {
  name               = "landing"
  storage_account_id = module.stg_accs["adls"].resource_id

  depends_on = [module.stg_accs]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = "bronze"
  storage_account_id = module.stg_accs["adls"].resource_id
  depends_on = [module.stg_accs]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "curated" {
  name               = "curated"
  storage_account_id = module.stg_accs["adls"].resource_id

  depends_on = [module.stg_accs]
}




module "sql_mi" {
  source  = "Azure/avm-res-sql-managedinstance/azurerm"
  version = "0.2.1"

  administrator_login          = var.sql_mi_administrator_login
  administrator_login_password = var.sql_mi_administrator_password
  license_type                 = "LicenseIncluded"
  location                     = local.location
  name                         = local.names.sql_mi
  resource_group_name          = data.azurerm_resource_group.core.name
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = var.sql_mi_storage_size_in_gb
  subnet_id                    = data.azurerm_subnet.sql_mi.id
  vcores                       = var.sql_mi_vcores
  minimum_tls_version          = "1.2"
  public_data_endpoint_enabled = false
  zone_redundant_enabled       = local.is_prod
  service_principal_enabled    = true
  enable_telemetry             = var.enable_telemetry
  tags                         = local.tags
  

  managed_identities = {
    system_assigned = true
  }

  active_directory_administrator = {
    
    login_username                      = "sqlmi-principal"
    object_id                           = ""
    principal_type                      = "Group"
    azuread_authentication_only_enabled = true
    tenant_id                           = ""
  
  }

  databases = {
    ssis_db = {
    name = "db-pin-ppuk-ssis-dev-uks-001"
    
    tags                      = local.tags
    long_term_retention_policy = {
      monthly_retention = ""
      week_of_year      = number
      weekly_retention  = ""
      yearly_retention  = ""
    }
    point_in_time_restore = {
      restore_point_in_time = "35 days"
      source_database_id    = ""
    }
      

    
  }
  }
  

  diagnostic_settings = {
    logs = {
      workspace_resource_id = local.names.existing_log_workspace == null ? module.log_analytics_workspace.resource_id : data.azurerm_log_analytics_workspace.log_analytics_workspace.id
  }}
    

  depends_on = [module.log_analytics]
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  resource_type = "SqlServers"
  tier = "Standard"
}

module "adfs"{
  for_each = local.adfs
  source  = "Azure/avm-res-datafactory-factory/azurerm"
  version = "0.1.0"

  location                        = local.location
  name                            = each.value
  resource_group_name             = data.azurerm_resource_group.core.name
  enable_telemetry                = var.enable_telemetry
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  purview_id                      = one(azurerm_purview_account.this[*].id)
  tags                            = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings = {
    logs = {
      workspace_resource_id = local.names.existing_log_workspace == null ? module.log_analytics_workspace.resource_id : data.azurerm_log_analytics_workspace.log_analytics_workspace.id
  }}

  linked_service_key_vault = {
    platform = {
      name         = "ls-keyvault-platform"
      key_vault_id = module.key_vault.resource_id
    }
  }

  depends_on = [module.key_vault, module.log_analytics, azurerm_purview_account.this]
}

resource "azurerm_data_factory_integration_runtime_azure_ssis" "adf_ssis_ir" {
  for_each = module.adfs
  name            = "example"
  data_factory_id = module.adfs[each.key].resource_id
  location        = local.location

  node_size = "Standard_E16_v3"
  number_of_nodes = 1

  vnet_integration {
    subnet_id = data.azurerm_subnet.data_factory.id
  }

  catalog_info {
    server_endpoint = ""
  }



}



module "azureml" {
  count   = var.enable_analytics ? 1 : 0
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "0.9.0"

  location                      = local.location
  name                          = local.names.aml_workspace
  resource_group_name           = data.azurerm_resource_group.core.name
  enable_telemetry              = var.enable_telemetry
  public_network_access_enabled = false
  tags                          = local.tags

  key_vault = {
    resource_id = module.key_vault.resource_id
  }
  storage_account = {
    resource_id = module.stg_accs["blob"].resource_id (confirm)
  }
  managed_identities = {
    system_assigned = true
  }

  depends_on = [module.key_vault, module.stg_accs]
}


module "databricks-workspace" {
source  = "Azure/avm-res-databricks-workspace/azurerm"
version = "0.4.0"
  name = local.names.databricks_workspace
  location = local.location
  resource_group_name = data.azurerm_resource_group.core.name
  sku = "premium"
  enable_telemetry = var.enable_telemetry

  access_connector = { 
    ac1 ={
    name                = ""
    resource_group_name = data.azurerm_resource_group.core.name
    location            = local.location
    identity = {
      type         = "SystemAssigned"
    }
    tags = local.tags
  }

}

custom_parameters = {
    machine_learning_workspace_id                        = module.aml.resource_id
    nat_gateway_name                                     = ""
    public_ip_name                                       = ""
    no_public_ip                                         = ""
    public_subnet_name                                   = ""
    public_subnet_network_security_group_association_id  = ""
    private_subnet_name                                  = ""
    private_subnet_network_security_group_association_id = ""
    storage_account_name                                 = ""
    storage_account_sku_name                             = ""
    virtual_network_id                                   = data.azurerm_virtual_network.db_vnet.id
    vnet_address_prefix                                  = ""
}

}



resource "azurerm_purview_account" "this" {
  count                       = var.manage_purview ? 1 : 0
  name                        = local.names.purview
  resource_group_name         = data.azurerm_resource_group.core.name
  location                    = local.location
  public_network_enabled      = false
  managed_resource_group_name = "${local.names.purview}-managed"
  tags                        = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_diagnostic_setting" "purview" {
  count                      = var.manage_purview ? 1 : 0
  name                       = "diag-${local.names.purview}"
  target_resource_id         = azurerm_purview_account.this[0].id
  log_analytics_workspace_id = local.names.existing_log_workspace == null ? module.log_analytics_workspace.resource_id : data.azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [module.log_analytics]
}

module "avm-res-network-privateendpoint" {
for_each = local.private_endpoints
source  = "Azure/avm-res-network-privateendpoint/azurerm"
version = "0.2.0"
name = each.value.name
location = local.location
resource_group_name = data.azurerm_resource_group.core.name
network_interface_name = each.value.network_interface_name
subnet_resource_id = data.azurerm_subnet.private_endpoints.id
private_connection_resource_id = each.value.private_connection_resource_id
private_dns_zone_resource_ids = ["3423eae2-1486-4f97-9ad6-1cce099cea90", ]
tags = local.tags

depends_on = [module.key_vault, module.sql_mi, module.stg_accs, module.databricks-workspace, module.azureml ]
}
