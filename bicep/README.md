# Bicep Templates for ThorLabs Environment

This directory contains specialized Bicep templates for specific workloads and scenarios.

## Windows Server 2022 Entra ID Connect & MDI Template

### Files
- `windows-server-entra-id.bicep` - Main Bicep template for Windows Server 2022 VM
- `windows-server-entra-id.parameters.json` - Parameter file for deployment
- `windows-server-entra-id.parameters.template.json` - Template for creating custom parameter files

### Purpose
Deploys a Windows Server 2022 VM optimized for:
- Azure AD Connect (Entra ID Connect) deployment
- Microsoft Defender for Identity (MDI) sensor installation
- Domain Controller services
- Hybrid identity scenarios

### Security Features
- Network Security Group with restrictive rules for domain services
- Parameterized allowed source IPs for RDP access
- Separate subnets for domain services
- Premium storage for better performance and reliability

### Deployment

#### Prerequisites
1. Set up GitHub secrets:
   - `WINDOWS_ADMIN_PASSWORD` - Secure password for Windows administrator
   - `AZURE_CREDENTIALS` - Service principal credentials
   - `AZURE_SUBSCRIPTION_ID` - Target subscription ID

#### Using GitHub Actions
Use the automated workflow: `.github/workflows/deploy-windows-server.yml`

#### Manual Deployment
```bash
# Deploy with Azure CLI
az deployment group create \
  --name "thorlabs-windows-server-deployment" \
  --resource-group "thorlabs-rg" \
  --template-file bicep/windows-server-entra-id.bicep \
  --parameters adminPassword="YOUR-SECURE-PASSWORD" \
  --parameters @bicep/windows-server-entra-id.parameters.json
```

### Post-Deployment Setup
After VM deployment, run the PowerShell setup scripts on the VM:

1. `scripts/windows-server-entra-prereqs.ps1` - Sets up prerequisites for Entra ID Connect
2. `scripts/windows-server-mdi-prereqs.ps1` - Sets up prerequisites for Microsoft Defender for Identity

### Parameters

| Parameter | Description | Default | Notes |
|-----------|-------------|---------|-------|
| `location` | Azure region | `eastus2` | |
| `vmName` | Virtual machine name | `thorlabs-vm2-eastus2` | Follows ThorLabs naming convention |
| `adminUsername` | Administrator username | | Required |
| `adminPassword` | Administrator password | | Required, use GitHub secret |
| `vmSize` | VM size | `Standard_D2s_v3` | Minimum for domain services |
| `vnetAddressPrefix` | VNet address space | `10.1.0.0/16` | |
| `subnetAddressPrefix` | Subnet address space | `10.1.1.0/24` | |
| `domainControllerIP` | Static IP for DC | `10.1.1.10` | |
| `allowedSourceIPs` | IPs allowed for RDP | `["0.0.0.0/0"]` | Restrict in production |
| `osDiskType` | OS disk storage type | `Premium_LRS` | Premium recommended |
| `osDiskSizeGB` | OS disk size | `128` | Minimum for domain services |

### Security Considerations
- **Change default allowed source IPs** - Restrict RDP access to known IP ranges
- **Use strong passwords** - Store in GitHub secrets or Azure Key Vault
- **Monitor access** - Enable Azure Security Center monitoring
- **Regular updates** - Keep OS and security patches up to date

### Troubleshooting
- Check deployment logs in Azure portal
- Verify NSG rules if connectivity issues occur
- Ensure VM has internet access for Windows updates
- Check PowerShell execution policy if scripts fail

For detailed setup instructions, see `docs/windows-server-entra-id-setup.md`.