variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "uat", "preprod", "prod"], var.environment)
    error_message = "environment must be one of dev, test, uat, preprod, prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

variable "asset" {
  description = "Asset shorthand used in resource names. PDF examples use ppuk, while the naming guidance also mentions puk."
  type        = string
  default     = "ppuk"
}

variable "region_code" {
  description = "Short region code used in resource names."
  type        = string
  default     = "uks"
}

variable "owner" {
  description = "Business or platform owner tag."
  type        = string
}

variable "cost_centre" {
  description = "Cost centre tag."
  type        = string
}

variable "sql_mi_administrator_login" {
  description = "Temporary SQL MI administrator login for bootstrap."
  type        = string
  default     = "sqlmiadmin"
}

variable "sql_mi_administrator_password" {
  description = "Temporary SQL MI administrator password. Supply via TF_VAR_sql_mi_administrator_password."
  type        = string
  sensitive   = true
}

variable "sql_mi_vcores" {
  description = "SQL MI vCore count. PDF starting point is 16 vCores."
  type        = number
  default     = 16
}

variable "sql_mi_storage_size_in_gb" {
  description = "SQL MI storage size in GB."
  type        = number
  default     = 4096
}

variable "enable_native_adf" {
  description = "Deploy general-purpose ADF for future native pipelines."
  type        = bool
  default     = false
}

variable "enable_analytics" {
  description = "Deploy optional Azure ML and Databricks LAB scaffolding."
  type        = bool
  default     = false
}

variable "enable_telemetry" {
  description = "Enable Azure Verified Module telemetry."
  type        = bool
  default     = true
}

variable "enable_function_app_vnet_integration" {
  description = "Wire the Function App to the snet-function-app subnet. Subnet must be pre-provisioned with Microsoft.Web/serverFarms delegation."
  type        = bool
  default     = false
}

variable "manage_purview" {
  description = "Create the Azure Purview account. PPG allows only one Purview instance per tenancy, so set false in environments where Purview is shared from another deployment."
  type        = bool
  default     = true
}
