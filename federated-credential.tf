terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.7.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "bc884483-24ef-40c5-b8d4-0c35a50ca8f8"
}

provider "azuread" {

}

variable "organization" {
  type        = string
  description = "The Terraform Cloud organization name"
}

variable "project" {
  type        = string
  description = "The Terraform Cloud project name"
}

variable "workspace" {
  type        = string
  description = "The Terraform Cloud workspace name"
}

variable "sp_name" {
  type        = string
  description = "The name of the service principal to create"
}

variable "role" {
  type        = string
  description = "The Azure role to assign to the service principal"
  default     = null
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where the role will be assigned"
  default     = null
}

resource "azuread_application" "this" {
  display_name = var.sp_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each       = toset(["plan", "apply"])
  application_id = azuread_application.this.id
  display_name   = "tfc-${each.key}-federated-credential"
  description    = "Federated credential for Terraform Cloud ${each.key} phase"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:${var.organization}:project:${var.project}:workspace:${var.workspace}:run_phase:${each.key}"
  depends_on     = [azuread_service_principal.this]
}

resource "azurerm_role_assignment" "this" {
  count                = var.role != null && var.subscription_id != null ? 1 : 0
  principal_id         = azuread_service_principal.this.object_id
  role_definition_name = var.role
  scope                = "/subscriptions/${var.subscription_id}"
}

output "client_id" {
  value       = azuread_application.this.client_id
  description = "The client ID (application ID) of the created Azure AD application"
}

output "configuration_instructions" {
  value = <<EOF
Add the following environment variables to your Terraform Cloud workspace:
- TFC_AZURE_PROVIDER_AUTH = true
- TFC_AZURE_RUN_CLIENT_ID = ${azuread_application.this.client_id}
EOF
}
