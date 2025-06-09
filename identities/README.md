# Identity Management as Code

This directory contains tools and examples for managing Azure Entra (Azure AD) users and identities as code using both PowerShell and Terraform approaches.

---

## Directory Structure

```
identities/
├── README.md                           # This file
├── powershell/
│   ├── Manage-EntraUsers.ps1          # PowerShell script for user management
│   └── Configure-VMAutoShutdown.ps1   # PowerShell script for VM auto-shutdown
└── terraform/
    ├── main.tf                         # Terraform configuration for Azure AD users
    ├── variables.tf                    # Variable definitions
    ├── terraform.tfvars.example       # Example variable values
    └── user_info_template.txt          # Template for user information export
```

---

## PowerShell Scripts

### Prerequisites

Before using the PowerShell scripts, ensure you have the required modules installed:

```powershell
# For Azure AD user management
Install-Module Microsoft.Graph -Force -AllowClobber

# For Azure VM management
Install-Module Az -Force -AllowClobber
```

### 1. Manage-EntraUsers.ps1

This script provides comprehensive Azure Entra (Azure AD) user management capabilities using the Microsoft Graph PowerShell module.

#### Features:
- Create new users with customizable attributes
- List all users in the tenant
- Get detailed information about specific users
- Delete users (with confirmation)
- Generate secure random passwords
- Support for department, job title, and other user attributes

#### Authentication:
```powershell
# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'
```

#### Usage Examples:

**Create a new user:**
```powershell
.\Manage-EntraUsers.ps1 -Action Create `
    -UserPrincipalName "john.doe@yourdomain.com" `
    -DisplayName "John Doe" `
    -MailNickname "john.doe" `
    -Department "IT Lab" `
    -JobTitle "Lab Administrator"
```

**List all users:**
```powershell
.\Manage-EntraUsers.ps1 -Action List
```

**Get specific user details:**
```powershell
.\Manage-EntraUsers.ps1 -Action Get -UserPrincipalName "john.doe@yourdomain.com"
```

**Delete a user:**
```powershell
.\Manage-EntraUsers.ps1 -Action Delete -UserPrincipalName "john.doe@yourdomain.com"
```

### 2. Configure-VMAutoShutdown.ps1

This script configures automatic shutdown for Azure VMs at 7pm EST (or custom time) to help control lab costs.

#### Features:
- Configure daily auto-shutdown schedules
- Customizable shutdown time and timezone
- Email and webhook notifications
- View current auto-shutdown status
- Remove auto-shutdown configuration

#### Authentication:
```powershell
# Connect to Azure
Connect-AzAccount
```

#### Usage Examples:

**Configure auto-shutdown at 7pm EST:**
```powershell
.\Configure-VMAutoShutdown.ps1 `
    -ResourceGroupName "thorlabs-rg" `
    -VMName "thorlabs-vm1-eastus2"
```

**Configure with custom time and notifications:**
```powershell
.\Configure-VMAutoShutdown.ps1 `
    -ResourceGroupName "thorlabs-rg" `
    -VMName "thorlabs-vm1-eastus2" `
    -ShutdownTime "18:30" `
    -TimeZone "Pacific Standard Time" `
    -EnableNotifications `
    -NotificationEmail "admin@yourdomain.com"
```

**Check auto-shutdown status:**
```powershell
.\Configure-VMAutoShutdown.ps1 `
    -ResourceGroupName "thorlabs-rg" `
    -VMName "thorlabs-vm1-eastus2" `
    -Action Status
```

**Remove auto-shutdown:**
```powershell
.\Configure-VMAutoShutdown.ps1 `
    -ResourceGroupName "thorlabs-rg" `
    -VMName "thorlabs-vm1-eastus2" `
    -Action Remove
```

---

## Terraform Configuration

### Prerequisites

1. **Install Terraform** (version >= 1.0):
   - Download from [terraform.io](https://www.terraform.io/downloads)
   - Add to your system PATH

2. **Azure CLI** for authentication:
   ```bash
   # Install Azure CLI and login
   az login
   ```

3. **Required Permissions**:
   - User Administrator (to create/manage users)
   - Groups Administrator (to create/manage groups)

### Configuration Files

#### main.tf
The main Terraform configuration that defines:
- Azure AD user creation with customizable attributes
- Optional group creation and membership
- Password generation
- Output values for created resources

#### variables.tf
Defines all configurable variables with:
- Validation rules for input values
- Default values for common scenarios
- Comprehensive descriptions

#### terraform.tfvars.example
Example variable file showing how to customize the deployment.

### Usage

1. **Copy and customize variables:**
   ```bash
   cd identities/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

5. **View the generated password:**
   ```bash
   terraform output -raw user_password
   ```

6. **Clean up (when done):**
   ```bash
   terraform destroy
   ```

### Example terraform.tfvars

```hcl
# User configuration
username     = "lab.user"
display_name = "Lab User"
mail_nickname = "lab.user"

# User attributes
department         = "IT Lab"
job_title         = "Lab Technician"
office_location   = "Building A, Floor 2"
usage_location    = "US"

# Contact information
business_phones = ["+1-555-123-4567"]
mobile_phone    = "+1-555-987-6543"

# Account settings
account_enabled       = true
force_password_change = true

# Group management
create_lab_group = true
lab_group_name   = "ThorLabs-Users"

# Export settings
export_user_info = true
```

---

## Security Best Practices

### PowerShell Scripts
- **Never hardcode passwords** in scripts
- **Use secure credential storage** for automation scenarios
- **Review and limit permissions** granted to service accounts
- **Enable MFA** for administrative accounts
- **Regularly audit user accounts** and remove unused ones

### Terraform
- **Use remote state** for production environments
- **Store terraform.tfvars securely** and never commit to source control
- **Use service principals** with minimal required permissions
- **Enable state file encryption** when using remote backends
- **Review plans carefully** before applying changes

### General
- **Follow principle of least privilege** when assigning permissions
- **Use time-limited access** where possible
- **Monitor and log** all identity operations
- **Implement proper approval workflows** for production changes
- **Keep documentation updated** as environment evolves

---

## Integration with ThorLabs Environment

These identity management tools integrate with the existing ThorLabs lab environment:

### Resource Naming
Follow the established naming convention: `{projectname}-{service}{number}-{region}`
- Example: `thorlabs-user1-eastus`, `thorlabs-labgroup1-eastus`

### Cost Control
- **VM Auto-shutdown**: Automatically deallocate VMs at 7pm EST to minimize costs
- **User Lifecycle**: Remove unused accounts to maintain license efficiency
- **Group Management**: Organize users into groups for easier permission management

### Documentation
- **Log all manual actions** in the root `history.md` file
- **Update GitHub secrets** as needed for automation
- **Follow existing security practices** outlined in `docs/GITHUB_SECRETS_CHECKLIST.md`

---

## Troubleshooting

### Common PowerShell Issues

**Graph module not found:**
```powershell
Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser
```

**Permission denied errors:**
```powershell
# Ensure you have the required Graph permissions
Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'
```

**Azure connection issues:**
```powershell
# Clear cached credentials and reconnect
Clear-AzContext -Force
Connect-AzAccount
```

### Common Terraform Issues

**Authentication failures:**
```bash
# Ensure Azure CLI is authenticated
az login
az account show
```

**Provider version conflicts:**
```bash
# Clean and reinitialize
rm -rf .terraform*
terraform init
```

**State file issues:**
```bash
# Check state and refresh
terraform state list
terraform refresh
```

---

## Contributing

When modifying these identity management tools:

1. **Test thoroughly** in a development environment first
2. **Update documentation** to reflect any changes
3. **Follow established coding standards** and commenting practices
4. **Validate scripts** with PowerShell ScriptAnalyzer
5. **Check Terraform configurations** with `terraform validate`
6. **Update examples** if adding new functionality

---

For questions or issues with identity management, refer to the main project documentation in the `docs/` folder or consult the Azure documentation for the latest API changes and best practices.