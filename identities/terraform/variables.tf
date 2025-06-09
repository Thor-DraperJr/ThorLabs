# variables.tf
# Variable definitions for Azure AD user management Terraform configuration

variable "username" {
  description = "Username portion of the UPN (without @domain.com)"
  type        = string
  default     = "testuser"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.username))
    error_message = "Username must contain only alphanumeric characters, dots, underscores, and hyphens."
  }
}

variable "display_name" {
  description = "Display name for the user"
  type        = string
  default     = "Test User"
}

variable "mail_nickname" {
  description = "Mail nickname for the user (used for email alias)"
  type        = string
  default     = "testuser"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.mail_nickname))
    error_message = "Mail nickname must contain only alphanumeric characters, dots, underscores, and hyphens."
  }
}

variable "force_password_change" {
  description = "Whether to force the user to change password on next sign-in"
  type        = bool
  default     = true
}

variable "department" {
  description = "Department of the user"
  type        = string
  default     = "IT Lab"
}

variable "job_title" {
  description = "Job title of the user"
  type        = string
  default     = "Lab User"
}

variable "office_location" {
  description = "Office location of the user"
  type        = string
  default     = null
}

variable "usage_location" {
  description = "Usage location for the user (ISO 3166-1 alpha-2 country code)"
  type        = string
  default     = "US"
  
  validation {
    condition     = can(regex("^[A-Z]{2}$", var.usage_location))
    error_message = "Usage location must be a valid 2-letter ISO 3166-1 alpha-2 country code."
  }
}

variable "business_phones" {
  description = "List of business phone numbers"
  type        = list(string)
  default     = []
}

variable "mobile_phone" {
  description = "Mobile phone number"
  type        = string
  default     = null
}

variable "account_enabled" {
  description = "Whether the user account is enabled"
  type        = bool
  default     = true
}

variable "create_lab_group" {
  description = "Whether to create a lab group and add the user to it"
  type        = bool
  default     = true
}

variable "lab_group_name" {
  description = "Name for the lab group (if creating one)"
  type        = string
  default     = "ThorLabs-Users"
}

variable "export_user_info" {
  description = "Whether to export user information to a local file"
  type        = bool
  default     = false
}