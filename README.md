# PPUK Data Platform Landing Zone

Terraform infrastructure-as-code for the PPUK Tier 1 Data Platform landing zone described in the technical requirements PDF.

## Scope

This repository provisions Azure landing zone resources only. It does not migrate SQL databases, deploy SSIS packages, refactor ETL pipelines, move production data, or configure reports.

Resource groups, the VNet, and its subnets are assumed to be pre-provisioned by the platform team and are looked up via data sources by the names defined in `locals.tf`.

## Azure Verified Modules

The implementation uses Azure Verified Modules for the main Azure resources:

- Log Analytics workspace
- Key Vault (RBAC authorization)
- Storage accounts (ADLS Gen2, AAE blob, function-app storage)
- SQL Managed Instance
- Data Factory (SSIS IR + optional native)
- Optional Azure Machine Learning workspace
- Optional Databricks workspace
- Function App (linux, AVM web-site)

Native AzureRM resources are used for items not covered by AVM: Azure Purview (`azurerm_purview_account`), the Function App App Service Plan / App Insights, storage lifecycle policy, ADLS filesystems, and RBAC role assignments wiring system-assigned managed identities into Key Vault, ADLS, Blob, and Purview.

## Environments

- `dev`
- `test`
- `uat`
- `preprod`
- `prod`

## Validate

Terraform is required locally.

```bash
./scripts/validate.sh
```

## Plan

```bash
cd terraform
terraform init
terraform plan -var-file=envs/dev.tfvars
```

## Pre-Deployment Decisions

Confirm these before the first `terraform apply`:

- Whether the asset code must be `ppuk` or `puk`.
- Subscription IDs and remote backend storage for each environment.
- CIDR ranges that do not conflict with PPG hub/spoke networking.
- Required private DNS zone ownership model.
- PPG Calandra mandatory tag names and allowed values.
- Whether SQL MI bootstrap should allow temporary SQL auth or Entra-only setup.
- Whether production requires SQL MI geo-replication immediately.
- Whether Microsoft Purview is existing and should be integrated by ID instead of provisioned. Purview is a tenancy-wide singleton (`ppg-apv-ppuk-uks-001`); set `manage_purview = false` in environments where it has already been deployed.
- Whether the Function App needs VNet integration (`enable_function_app_vnet_integration`). Requires a pre-provisioned `snet-function-app` subnet delegated to `Microsoft.Web/serverFarms`.
- Sentinel / Log Analytics workspace target if centralised outside this subscription.
- Exact Azure DevOps project and service connection names.
