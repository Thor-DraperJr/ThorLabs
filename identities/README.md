# ThorLabs Identity Management Scripts

This directory contains PowerShell scripts for identity and resource management tasks that cannot be handled through Bicep templates. These scripts align with the repository's Bicep-first Infrastructure as Code (IaC) approach, but provide automation for tasks that are not supported by Bicep.

---

## Scripts Overview

- [`Manage-EntraUsers.ps1`](Manage-EntraUsers.ps1) — Azure AD (Entra ID) user management (create, list, delete users)
- [`Schedule-ResourceShutdown.ps1`](Schedule-ResourceShutdown.ps1) — Schedule automatic shutdown of Azure VMs and other resources

---

## Prerequisites

### PowerShell Modules
The following PowerShell modules must be installed:

```powershell
# Install Azure PowerShell modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name Microsoft.Graph -Force -AllowClobber

# Import modules
Import-Module Az
Import-Module Microsoft.Graph
```

### Authentication
You must authenticate with both Azure and Microsoft Graph before running these scripts:

```powershell
# Authenticate with Azure
Connect-AzAccount

# Authenticate with Microsoft Graph (required for Entra ID operations)
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
```

### Required Permissions
Your account must have the following permissions:
- **Azure**: Contributor or higher on the target subscription/resource groups
- **Entra ID**: User Administrator or Global Administrator for user management operations

---

## Script Usage

### Azure AD (Entra ID) User Management

```powershell
# List all users
.\Manage-EntraUsers.ps1 -Action List

# Create a new user
.\Manage-EntraUsers.ps1 -Action Create -UserPrincipalName "john.doe@yourdomain.com" -DisplayName "John Doe" -Password "TempPassword123!"

# Delete a user
.\Manage-EntraUsers.ps1 -Action Delete -UserPrincipalName "john.doe@yourdomain.com"

# Get help
Get-Help .\Manage-EntraUsers.ps1 -Full
```

### Resource Shutdown Scheduling

```powershell
# Schedule shutdown for all VMs in a resource group at 7 PM EST
.\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -ShutdownTime "19:00" -TimeZone "Eastern Standard Time"

# Schedule shutdown for specific VMs
.\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -VMNames @("thorlabs-vm1-eastus2", "thorlabs-vm2-eastus2") -ShutdownTime "19:00" -TimeZone "Eastern Standard Time"

# Schedule shutdown with email notifications
.\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -ShutdownTime "19:00" -TimeZone "Eastern Standard Time" -NotificationEmail "admin@yourdomain.com"

# Get help
Get-Help .\Schedule-ResourceShutdown.ps1 -Full
```

---

## Integration with Bicep-first Approach

These PowerShell scripts complement the repository's Bicep-first IaC approach by handling tasks that cannot be accomplished through ARM/Bicep templates:

- **User identity management**: Bicep cannot create or manage Azure AD users
- **Dynamic resource scheduling**: Bicep creates resources but cannot handle time-based operational tasks
- **Cross-service automation**: Some operations require coordination between multiple Azure services

All infrastructure provisioning should continue to use Bicep templates in the `infra/` directory. These scripts are for operational management only.

---

## Security Best Practices

- **Never hardcode credentials** in scripts or commit them to the repository
- **Use secure strings** for password parameters when possible
- **Log all actions** to `history.md` in the repository root for traceability
- **Test scripts** in a development environment before running in production
- **Follow least privilege** principles when assigning permissions

---

## Troubleshooting

### Common Issues

1. **Authentication failures**: Ensure you're connected to both Azure and Microsoft Graph with sufficient permissions
2. **Module not found**: Install required PowerShell modules using the commands in Prerequisites
3. **Permission denied**: Verify your account has the required Azure and Entra ID roles

### Support

For issues related to these scripts, check:
1. The `history.md` file for recent command executions
2. Azure portal for resource status and logs
3. PowerShell execution policies and module versions

---

> **Note**: This identity management approach does not use Terraform or other IaC tools, maintaining consistency with the repository's Bicep-focused infrastructure strategy.