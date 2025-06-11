# Bicep Templates for ThorLabs Environment

This directory contains specialized Bicep templates for specific workloads and scenarios.

## Scripts Storage Account Template

### Files
- `scripts-storage.bicep` - Storage account for centralized script distribution
- `scripts-storage.parameters.json` - Parameter file for deployment

### Purpose
Deploys a secure storage account for script distribution to VMs with:
- Blob storage container for scripts (`scripts`)
- HTTPS-only traffic enforcement
- 7-day deletion retention policy
- Appropriate tagging for cost management and governance

### Security Features
- TLS 1.2 minimum encryption
- HTTPS-only traffic
- No public blob access
- Storage account key access (suitable for lab environment)

### Deployment
```bash
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file ./bicep/scripts-storage.bicep \
  --parameters @./bicep/scripts-storage.parameters.json
```

### Usage
See [`docs/INSTRUCTIONS.md`](../docs/INSTRUCTIONS.md) for detailed instructions on uploading and downloading scripts from VMs.

---

## Windows Server 2022 Base Template

### Files
- `windows-server-base.bicep` - Main Bicep template for Windows Server 2022 VM
- `windows-server-base.parameters.json` - Parameter file for deployment

### Purpose
Deploys a basic Windows Server 2022 VM with:
- RDP access with public IP
- Network Security Group with basic security rules
- Standard Windows Server 2022 Datacenter configuration
- Auto-shutdown policies for cost control

### Security Features
- Network Security Group with RDP access rules
- Parameterized allowed source IPs for RDP access
- Premium storage for better performance and reliability
- Standard ThorLabs tagging for cost management

### Deployment

#### Prerequisites
1. Set up GitHub secrets:
   - `ADMIN_PASSWORD` - Secure password for administrator (used for both Ubuntu and Windows VMs)
   - `AZURE_CREDENTIALS` - Service principal credentials
   - `AZURE_SUBSCRIPTION_ID` - Target subscription ID

#### Using GitHub Actions
Use the main deployment workflow: `.github/workflows/deploy.yml`

#### Manual Deployment
```bash
# Deploy with Azure CLI
az deployment group create \
  --name "thorlabs-windows-server-deployment" \
  --resource-group "thorlabs-rg" \
  --template-file bicep/windows-server-base.bicep \
  --parameters adminPassword="YOUR-SECURE-PASSWORD" \
  --parameters @bicep/windows-server-base.parameters.json
```

### Parameters

| Parameter | Description | Default | Notes |
|-----------|-------------|---------|-------|
| `location` | Azure region | `eastus2` | |
| `vmName` | Virtual machine name | `thorlabs-vm2-eastus2` | Follows ThorLabs naming convention |
| `adminUsername` | Administrator username | `azureuser` | |
| `adminPassword` | Administrator password | | Required, use GitHub secret |
| `vmSize` | VM size | `Standard_B2s` | Cost-effective for basic workloads |
| `allowedSourceIPs` | IPs allowed for RDP | `["0.0.0.0/0"]` | Restrict in production |

### Security Considerations
- **Change default allowed source IPs** - Restrict RDP access to known IP ranges
- **Use strong passwords** - Store in GitHub secrets or Azure Key Vault
- **Monitor access** - Enable Azure Security Center monitoring
- **Regular updates** - Keep OS and security patches up to date

### Troubleshooting
- Check deployment logs in Azure portal
- Verify NSG rules if connectivity issues occur
- Ensure VM has internet access for Windows updates
- Verify RDP access through Azure portal if connection issues occur