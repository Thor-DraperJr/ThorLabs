# ThorLabs Deployment Guide

## 🚀 Quick Start Options

### Option 1: Automated GitHub Deployment (Recommended)
```bash
# 1. Set up GitHub Actions secrets (see GitHub Workflows guide)
# 2. Push to main branch - complete lab deploys automatically
# 3. Monitor in GitHub Actions tab
```

### Option 2: Interactive Script Deployment
```bash
# Interactive deployment with guided setup
./scripts/deploy-lab.sh
```

### Option 3: Direct Azure CLI Deployment
```bash
# Core lab deployment
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters adminPassword="YourSecurePassword123!"

# Enhanced lab with all services
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters @infra/master-deployment.parameters.json \
               adminPassword="YourSecurePassword123!"
```

---

## 🏗️ Infrastructure Architecture

### Core Infrastructure (Always Deployed)
- **Resource Group**: `thorlabs-rg-eastus2`
- **Virtual Network**: `thorlabs-lab-vnet` (10.10.0.0/16)
- **Subnet**: `thorlabs-lab-subnet` (10.10.0.0/24)
- **Network Security Group**: `thorlabs-lab-nsg` (SSH 22, RDP 3389)
- **Log Analytics**: `thorlabs-logs1-eastus2`
- **Key Vault**: `thorlabs-kv1-eastus2`

### Virtual Machines
- **Ubuntu Server**: `thorlabs-vm1-eastus2` (Standard_B2s)
- **Windows Server 2022**: `thorlabs-vm2-eastus2` (Standard_B2s)
- **Auto-shutdown**: 7 PM ET daily (enforced by Azure Policy)

### Optional Services
- **Container Instances**: Docker workloads
- **Azure SQL**: Database services  
- **PostgreSQL**: Open-source database
- **Cosmos DB**: NoSQL database
- **Storage Accounts**: File and blob storage
- **Microsoft Sentinel**: Security monitoring

---

## 📋 Prerequisites

### Local Development
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Bicep
az bicep install

# Login to Azure
az login

# Verify subscription
az account show
```

### GitHub Actions (If Using Automated Deployment)
- GitHub repository with Actions enabled
- Required secrets configured (see [GitHub Workflows guide](GITHUB_WORKFLOWS.md))
- Service principal with Contributor role

---

## 🎛️ Deployment Options

### Enhanced Deployment Types

#### Core Lab (~$30-50/month)
- Ubuntu and Windows VMs
- Networking and security
- Storage and monitoring
- Basic governance policies

#### Full Lab (~$60-100/month)  
- Core infrastructure
- Container services (Azure Container Instances)
- Database services (SQL, PostgreSQL, Cosmos DB)
- Advanced monitoring with Sentinel

#### Custom Lab
- Choose specific services to deploy
- Cost-optimized for targeted scenarios
- Selective feature enablement

### VM Sizing Options
- **Cost-optimized**: `Standard_B1s` (1 vCPU, 1GB RAM)
- **Balanced**: `Standard_B2s` (2 vCPU, 4GB RAM) - Default
- **Performance**: `Standard_D2s_v3` (2 vCPU, 8GB RAM)

---

## 🔧 Interactive Script Features

The `deploy-lab.sh` script provides:

### Prerequisites Check
- Azure CLI installation and login status
- Bicep CLI availability
- Subscription access verification

### Template Validation
```bash
# Validates templates before deployment
az bicep build --file infra/master-deployment.bicep --stdout > /dev/null
az bicep build --file infra/enhanced-lab.bicep --stdout > /dev/null
```

### Interactive Configuration
- Deployment type selection (core/full/custom)
- VM size configuration
- Password setup with validation
- Deployment confirmation

### Post-Deployment Information
- Resource connection details
- Cost estimates
- Next steps guidance

---

## 🛡️ Security Configuration

### Azure AD Authentication
```bash
# Get your Azure identity
./scripts/get-azure-identity.sh

# Deploy with Azure AD admin
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters \
    enableAzureADAuth=true \
    azureADAdminUpn='your-email@domain.com' \
    azureADAdminObjectId='your-object-id' \
    adminPassword='YourSecurePassword123!'
```

### Microsoft Sentinel Setup
```bash
# Deploy security monitoring
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters \
    enableSentinel=true \
    adminPassword='YourSecurePassword123!'
```

### Policy Enforcement
- VM auto-shutdown tags (automatic)
- Resource naming conventions (enforced)
- Cost control governance (enabled)

---

## 💾 Script Distribution System

### Storage Account Setup
```bash
# Deploy scripts storage
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file ./bicep/scripts-storage.bicep \
  --parameters @./bicep/scripts-storage.parameters.json
```

### Upload Scripts
```bash
# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group thorlabs-rg \
  --account-name thorlabsst1eastus2 \
  --query '[0].value' -o tsv)

# Upload PowerShell script for Windows VMs
az storage blob upload \
  --account-name thorlabsst1eastus2 \
  --account-key $STORAGE_KEY \
  --container-name scripts \
  --name windows-setup.ps1 \
  --file ./scripts/windows-setup.ps1

# Upload shell script for Ubuntu VMs  
az storage blob upload \
  --account-name thorlabsst1eastus2 \
  --account-key $STORAGE_KEY \
  --container-name scripts \
  --name ubuntu-setup.sh \
  --file ./scripts/ubuntu-setup.sh
```

### Download Scripts on VMs

#### Ubuntu Server
```bash
# Install Azure CLI if needed
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Authenticate and download
az login
az storage blob download \
  --account-name thorlabsst1eastus2 \
  --container-name scripts \
  --name ubuntu-setup.sh \
  --file /tmp/ubuntu-setup.sh \
  --auth-mode login

# Execute script
chmod +x /tmp/ubuntu-setup.sh
/tmp/ubuntu-setup.sh
```

#### Windows Server
```powershell
# Install Azure CLI if needed
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Authenticate and download
az login
az storage blob download `
  --account-name thorlabsst1eastus2 `
  --container-name scripts `
  --name windows-setup.ps1 `
  --file C:\temp\windows-setup.ps1 `
  --auth-mode login

# Execute script
PowerShell.exe -ExecutionPolicy Bypass -File C:\temp\windows-setup.ps1
```

---

## 🔍 Validation & Testing

### Local Template Testing
```bash
# Test template compilation
az bicep build --file infra/master-deployment.bicep --stdout > /dev/null

# Validate deployment (what-if)
az deployment sub what-if \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters adminPassword="TestPassword123!"
```

### VS Code Integration
1. Open any .bicep file (e.g., `infra/lab.bicep`)
2. Save file (Ctrl+S) - auto-validates syntax
3. Command Palette > "Bicep: Build" - validates compilation
4. Command Palette > "Azure: Sign In" - authenticate
5. Right-click .bicep file > "Deploy to Resource Group" - test deploy

### Post-Deployment Verification
```bash
# Check resource group
az group show --name thorlabs-rg-eastus2

# List all resources
az resource list --resource-group thorlabs-rg-eastus2 --output table

# Check VM status
az vm list --resource-group thorlabs-rg-eastus2 --show-details --output table

# Verify auto-shutdown tags
az vm show --resource-group thorlabs-rg-eastus2 --name thorlabs-vm1-eastus2 --query tags
```

---

## 💰 Cost Management

### Automatic Cost Controls
- **VM Auto-shutdown**: 7 PM ET daily (saves ~60% on compute costs)
- **B-series VMs**: Burstable performance (cost-optimized)
- **Shared resources**: Single VNet and NSG for multiple VMs
- **Policy enforcement**: Prevents expensive configurations

### Manual Cost Control
```bash
# Stop all VMs
az vm stop --resource-group thorlabs-rg-eastus2 --name thorlabs-vm1-eastus2
az vm stop --resource-group thorlabs-rg-eastus2 --name thorlabs-vm2-eastus2

# Deallocate to stop billing
az vm deallocate --resource-group thorlabs-rg-eastus2 --name thorlabs-vm1-eastus2
az vm deallocate --resource-group thorlabs-rg-eastus2 --name thorlabs-vm2-eastus2

# Start VMs when needed
az vm start --resource-group thorlabs-rg-eastus2 --name thorlabs-vm1-eastus2
az vm start --resource-group thorlabs-rg-eastus2 --name thorlabs-vm2-eastus2
```

### Cost Estimates
- **Core Lab**: $30-50/month (2 VMs with auto-shutdown)
- **Full Lab**: $60-100/month (includes databases and containers)
- **Development Mode**: $10-20/month (minimal resources, frequent shutdown)

---

## 🧹 Environment Cleanup

### Complete Environment Removal
```bash
# Using cleanup workflow (recommended)
# 1. Go to Actions tab → "Cleanup Azure Lab Environment"
# 2. Type "DELETE" to confirm
# 3. Click "Run workflow"

# Manual cleanup
az group delete --name thorlabs-rg-eastus2 --yes --no-wait

# Verify cleanup
az group exists --name thorlabs-rg-eastus2
```

### Selective Resource Cleanup
```bash
# Stop and deallocate VMs only
az vm deallocate --resource-group thorlabs-rg-eastus2 --name thorlabs-vm1-eastus2
az vm deallocate --resource-group thorlabs-rg-eastus2 --name thorlabs-vm2-eastus2

# Remove databases only (preserve VMs)
az sql server delete --resource-group thorlabs-rg-eastus2 --name thorlabs-sql1-eastus2 --yes
az postgres server delete --resource-group thorlabs-rg-eastus2 --name thorlabs-pg1-eastus2 --yes
```

---

## 🚨 Troubleshooting

### Common Issues
| Issue | Solution |
|-------|----------|
| **Template validation fails** | Run `az bicep build --file <template>` to check syntax |
| **Authentication errors** | Verify `az login` and subscription access |
| **Resource naming conflicts** | Delete existing resources or use unique names |
| **Deployment timeouts** | Use smaller VM sizes or deploy in stages |
| **Permission denied** | Ensure service principal has Contributor role |

### Debug Commands
```bash
# Check Azure CLI version
az version

# List subscriptions
az account list --output table

# Check current subscription
az account show

# List recent deployments
az deployment sub list --query "[?name contains 'thorlabs']" --output table

# Get deployment details
az deployment sub show --name <deployment-name>
```

---

## 📚 Related Documentation

- **[GitHub Workflows Guide](GITHUB_WORKFLOWS.md)** - Complete GitHub Actions setup
- **[Repository Guide](REPO_GUIDE.md)** - Project structure and navigation
- **[Quick Reference](QUICK_REFERENCE.md)** - Essential commands and tips
- **Infrastructure Templates** - `infra/` directory
- **Deployment Scripts** - `scripts/` directory

---

*This guide consolidates all deployment procedures for the ThorLabs environment. Choose the deployment method that best fits your workflow and requirements.*
