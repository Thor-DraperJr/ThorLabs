# Azure AD Authentication Setup Guide

## Overview
Your ThorLabs infrastructure now supports **passwordless authentication** using your Azure AD identity. This eliminates the need to create and manage separate usernames and passwords for databases and services.

## Benefits of Azure AD Authentication
- ✅ **No passwords to manage** - Use your existing Azure identity
- ✅ **Enhanced security** - MFA and conditional access support
- ✅ **Centralized access management** - Manage access through Azure AD
- ✅ **Audit and compliance** - All access is logged and auditable

## Quick Start

### 1. Get Your Azure Identity Information
```bash
# Login to Azure (if not already logged in)
az login

# Run the helper script to get your identity info
./scripts/get-azure-identity.sh
```

### 2. Deploy with Azure AD Authentication
```bash
# Deploy with your Azure identity as admin
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters \
    adminUsername='thorlabsadmin' \
    enableAzureADAuth=true \
    azureADAdminUpn='your-email@domain.com' \
    azureADAdminObjectId='your-object-id-from-script'
```

### 3. Connect to Your Resources

#### SQL Database (Azure AD Authentication)
```bash
# Using Azure CLI
az sql db show-connection-string \
  --server thorlabs-sql1-eastus2 \
  --name thorlabs-db1-eastus2 \
  --auth-type ADIntegrated

# Connection string format:
# Server=thorlabs-sql1-eastus2.database.windows.net;Database=thorlabs-db1-eastus2;Authentication=Active Directory Default;
```

#### PostgreSQL (Azure AD Authentication)
```bash
# Get access token for PostgreSQL
az account get-access-token --resource-type oss-rdbms

# Connect using psql with token authentication
psql "host=thorlabs-pg1-eastus2.postgres.database.azure.com user=your-email@domain.com dbname=thorlabstestdb sslmode=require"
```

#### Virtual Machines
```bash
# Ubuntu VM with SSH key (no password needed)
ssh -i ~/.ssh/your-private-key thorlabsadmin@thorlabs-vm1-eastus2-pip-ip

# Windows VM (use the fallback password if needed)
# RDP to: thorlabs-vm2-eastus2-pip-ip
```

## Configuration Options

### Template Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `enableAzureADAuth` | `true` | Enable Azure AD authentication for databases |
| `azureADAdminUpn` | `''` | Your email address (UPN) |
| `azureADAdminObjectId` | `''` | Your Azure AD object ID |
| `adminPassword` | `TempPassword123!` | Fallback password (only used when Azure AD is disabled) |
| `sshPublicKey` | `''` | SSH public key for Ubuntu VM (recommended) |

### Authentication Flow
1. **Azure AD Enabled (Default)**:
   - Databases: Azure AD authentication only
   - Ubuntu VM: SSH key authentication (password disabled)
   - Windows VM: Local admin account (fallback)

2. **Azure AD Disabled**:
   - Databases: SQL authentication with username/password
   - VMs: Local admin accounts with passwords

## Service-Specific Connection Details

### Azure SQL Database
- **Server**: `thorlabs-sql1-eastus2.database.windows.net`
- **Database**: `thorlabs-db1-eastus2`
- **Authentication**: Azure AD Integrated
- **Tools**: Azure Data Studio, SQL Server Management Studio, Azure CLI

### PostgreSQL Flexible Server
- **Server**: `thorlabs-pg1-eastus2.postgres.database.azure.com`
- **Database**: `thorlabstestdb`
- **Authentication**: Azure AD
- **Tools**: psql, pgAdmin, Azure CLI

### Cosmos DB
- **Account**: `thorlabs-cosmos1-eastus2`
- **Database**: `thorlabsTestDB`
- **Authentication**: Account keys or Azure AD (depending on access method)

## Troubleshooting

### "Access Denied" Errors
1. Verify your Azure AD admin was configured correctly:
   ```bash
   az sql server ad-admin list --server thorlabs-sql1-eastus2 --resource-group thorlabs-rg
   ```

2. Check your Azure AD token:
   ```bash
   az account get-access-token --resource https://database.windows.net/
   ```

### Connection Issues
1. Ensure you're logged into Azure CLI:
   ```bash
   az account show
   ```

2. Verify firewall rules allow your IP:
   ```bash
   az sql server firewall-rule list --server thorlabs-sql1-eastus2 --resource-group thorlabs-rg
   ```

### SSH Key Issues
1. Generate a new SSH key pair:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/thorlabs_key
   ```

2. Use the public key content in deployment:
   ```bash
   cat ~/.ssh/thorlabs_key.pub
   ```

## Security Best Practices

1. **Use SSH keys** for Linux VMs instead of passwords
2. **Enable MFA** on your Azure AD account
3. **Use Conditional Access** policies for additional security
4. **Regularly rotate** any fallback passwords
5. **Monitor access logs** in Azure AD and service-specific logs

## Next Steps

1. **Configure your applications** to use Azure AD authentication
2. **Set up monitoring** and alerting for access patterns
3. **Implement least privilege** access controls
4. **Document your connection procedures** for your team
