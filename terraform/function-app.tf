module "function_app_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  location                          = local.location
  name                              = local.names.function_app_storage
  resource_group_name               = data.azurerm_resource_group.core.name
  account_kind                      = "StorageV2"
  account_replication_type          = local.is_prod ? "ZRS" : "LRS"
  account_tier                      = "Standard"
  shared_access_key_enabled         = true
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = true
  infrastructure_encryption_enabled = true
  enable_telemetry                  = var.enable_telemetry
  tags                              = local.tags

  managed_identities = {
    system_assigned = true
  }

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Allow"
  }
}

resource "azurerm_service_plan" "function_app" {
  name                = "${local.names.function_app_plan}"
  resource_group_name = data.azurerm_resource_group.data.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

resource "azurerm_application_insights" "function_app" {
  name                = "appi-${local.names.function_app}"
  resource_group_name = data.azurerm_resource_group.data.name
  location            = var.location
  application_type    = "web"
  workspace_id        = module.log_analytics.resource_id
  tags                = local.tags

  depends_on = [module.log_analytics]
}

resource "azurerm_linux_function_app" "this" {
  name                          = local.names.function_app
  resource_group_name           = data.azurerm_resource_group.data.name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.function_app.id
  storage_account_name          = module.function_app_storage.name
  storage_uses_managed_identity = true
  https_only                    = true
  public_network_access_enabled = false
  virtual_network_subnet_id     = var.enable_function_app_vnet_integration ? data.azurerm_subnet.function_app[0].id : null
  tags                          = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.function_app.connection_string
    "AzureWebJobsStorage__accountName"      = module.function_app_storage.name
    "WEBSITE_VNET_ROUTE_ALL"                = var.enable_function_app_vnet_integration ? "1" : "0"
  }

  depends_on = [module.function_app_storage, azurerm_application_insights.function_app]
}
