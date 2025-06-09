# main.tf
# Terraform configuration for managing Azure Entra (Azure AD) users as code
# This example demonstrates creating and managing users using the AzureAD provider

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Azure AD Provider
provider "azuread" {
  # Authentication will be handled via:
  # - Azure CLI: az login
  # - Service Principal: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
  # - Managed Identity: when running in Azure
}

# Data source to get information about the current Azure AD tenant
data "azuread_client_config" "current" {}

# Data source to get the domain information
data "azuread_domains" "example" {
  only_initial = true
}

locals {
  domain_name = data.azuread_domains.example.domains.0.domain_name
}

# Generate a random password for the user
resource "random_password" "user_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create an Azure AD user
resource "azuread_user" "example_user" {
  user_principal_name   = "${var.username}@${local.domain_name}"
  display_name          = var.display_name
  mail_nickname         = var.mail_nickname
  password              = random_password.user_password.result
  force_password_change = var.force_password_change

  # Optional attributes
  department            = var.department
  job_title            = var.job_title
  office_location      = var.office_location
  usage_location       = var.usage_location
  
  # Contact information
  business_phones      = var.business_phones
  mobile_phone         = var.mobile_phone
  
  # Account settings
  account_enabled      = var.account_enabled
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      password  # Ignore password changes after initial creation
    ]
  }
}

# Optional: Create an Azure AD group for lab users
resource "azuread_group" "lab_users" {
  count            = var.create_lab_group ? 1 : 0
  display_name     = var.lab_group_name
  description      = "Group for ${var.lab_group_name} lab environment users"
  security_enabled = true
  
  # Group owners (current user/service principal)
  owners = [data.azuread_client_config.current.object_id]
}

# Optional: Add the user to the lab group
resource "azuread_group_member" "lab_user_membership" {
  count            = var.create_lab_group ? 1 : 0
  group_object_id  = azuread_group.lab_users[0].object_id
  member_object_id = azuread_user.example_user.object_id
}

# Output the user details
output "user_details" {
  description = "Details of the created user"
  value = {
    object_id           = azuread_user.example_user.object_id
    user_principal_name = azuread_user.example_user.user_principal_name
    display_name        = azuread_user.example_user.display_name
    mail_nickname       = azuread_user.example_user.mail_nickname
    department          = azuread_user.example_user.department
    job_title           = azuread_user.example_user.job_title
  }
  sensitive = false
}

output "user_password" {
  description = "Generated password for the user (sensitive)"
  value       = random_password.user_password.result
  sensitive   = true
}

output "lab_group_details" {
  description = "Details of the lab group (if created)"
  value = var.create_lab_group ? {
    object_id    = azuread_group.lab_users[0].object_id
    display_name = azuread_group.lab_users[0].display_name
    description  = azuread_group.lab_users[0].description
  } : null
}

# Optional: Export user information to a local file for reference
resource "local_file" "user_info" {
  count = var.export_user_info ? 1 : 0
  content = templatefile("${path.module}/user_info_template.txt", {
    user_principal_name = azuread_user.example_user.user_principal_name
    display_name        = azuread_user.example_user.display_name
    object_id           = azuread_user.example_user.object_id
    department          = azuread_user.example_user.department
    job_title           = azuread_user.example_user.job_title
    domain_name         = local.domain_name
    created_date        = timestamp()
  })
  filename = "${path.module}/created_user_${var.username}.txt"
}