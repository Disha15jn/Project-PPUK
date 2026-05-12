locals {
  is_prod = var.environment == "prod"

  location = "uksouth"

  tags = {
    application = "ppuk-data-platform"
    asset       = var.asset
    environment = var.environment
    location    = "uksouth"
    owner       = var.owner
    costCentre  = var.cost_centre
    managedBy   = "terraform"
  }

  names = {
    rg_core      = ""
    rg_aml = ""
    log_analytics = "law-pin-ppuk-dev-uks-001"
    existing_log_workspace = ""
    key_vault     = "kv-pin-ppuk-dev-uks-001"
    sql_mi      = "sqlmi-pin-ppuk-dev-uks-001"
    
    aml_workspace = "aml-pin-ppuk-dev-uks-001"
    databricks    = "d"

    purview              = "apv-pin-ppuk-uks-001"
    function_app         = "ppg-afa-${var.asset}-plat-${var.region_code}-${var.environment}-001"
    function_app_plan    = "ppg-asp-${var.asset}-plat-${var.region_code}-${var.environment}-001"
    function_app_storage = "ppgst${var.asset}fa${var.region_code}${var.environment}001"
  }

  storage_accounts = {
    blob = {
      name = "stgpinppukblobdevuks001"
      is_hns_enabled = false
    }

    adls = {
      name = "stgpinppukadlsdevuks001"
      is_hns_enabled = true
    }
  }

  adfs = ["adf-pin-ppuk-frontend-dev-uks-001" , "adf-pin-ppuk-backend-dev-uks-001"]
  
  vnet_names = {
    sql_mi = ""
    databricks = ""
  } 

  subnet_names = {
    sql_mi            = ""
    private_endpoints = ""
    data_factory      = ""
    analytics         = ""
    function_app      = ""
  }
   

  private_endpoints = {
  key_vault = {
    name = "pe-kv-pin-ppuk-dev-uks-001"
    network_interface_name = "nic-pe-kv-pin-ppuk-dev-uks-001"
    private_connection_resource_id = ""
  }

  abs_stgacc = {
    name = "pe-abs-stgacc-pin-ppuk-dev-uks-001"
    network_interface_name = "nic-pe-abs-stgacc-pin-ppuk-dev-uks-001" 
    private_connection_resource_id = "" 
  }


  adls_stgacc = {
    name = "pe-adls-stgacc-pin-ppuk-dev-uks-001"
    network_interface_name = "nic-pe-adls-stgacc-pin-ppuk-dev-uks-001" 
    private_connection_resource_id = "" 
  }

  sql_mi = {
    name = "pe-sqlmi-pin-ppuk-dev-uks-001"
    network_interface_name = "nic-pe-sqlmi-pin-ppuk-dev-uks-001" 
    private_connection_resource_id = "" 
  }
  

  aml = {
    name = "pe-aml-pin-ppuk-dev-uks-001"
    network_interface_name = "nic-pe-aml-pin-ppuk-dev-uks-001" 
    private_connection_resource_id = ""
  }
}



}
