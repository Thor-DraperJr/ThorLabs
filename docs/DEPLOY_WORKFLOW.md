# GitHub Actions Workflow: Deploy Complete Lab Environment

This workflow automatically deploys the complete ThorLabs lab environment including both Ubuntu and Windows servers whenever you push to the `main` branch.

---

## Resources Deployed

The workflow deploys the following Azure resources:

1. **Ubuntu Server VM** (`thorlabs-vm1-eastus2`)
   - General purpose Linux workstation
   - Template: `infra/main.bicep`
   - Network: `10.0.0.0/16` address space

2. **Windows Server 2022 VM** (`thorlabs-vm2-eastus2`)
   - Configured for Entra ID Connect and Microsoft Defender for Identity
   - Template: `bicep/windows-server-entra-id.bicep`
   - Network: `10.1.0.0/16` address space

3. **Azure Policy Definitions**
   - VM auto-shutdown enforcement
   - Governance and compliance rules

4. **Supporting Infrastructure**
   - Virtual networks and subnets
   - Network security groups
   - Public IP addresses
   - Storage accounts and disks

---

## Prerequisites

Ensure you have set the following secrets in your repository (**Settings > Actions > Secrets and variables**):
- `AZURE_CREDENTIALS` - Service principal JSON for Azure authentication
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `ADMIN_PASSWORD` - Password for Ubuntu VM administrator account
- `WINDOWS_ADMIN_PASSWORD` - Password for Windows Server administrator account

For detailed instructions on setting up these secrets, see [`GITHUB_SECRETS_CHECKLIST.md`](GITHUB_SECRETS_CHECKLIST.md).

---

## Workflow Steps

The deployment workflow performs the following steps:

1. **Validation**: Validates both Bicep templates before deployment
2. **Ubuntu Deployment**: Deploys Ubuntu server infrastructure
3. **Windows Deployment**: Deploys Windows Server 2022 for Entra ID/MDI
4. **Policy Deployment**: Applies Azure governance policies
5. **Summary Output**: Provides deployment summary and next steps

---

## Current Workflow Configuration

The current workflow in `.github/workflows/deploy.yml` is configured as follows:

```yaml
name: Deploy Azure Lab Environment

on:
  push:
    branches:
      - main
  workflow_dispatch:  # Allow manual triggering

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
      WINDOWS_ADMIN_PASSWORD: ${{ secrets.WINDOWS_ADMIN_PASSWORD }}
      
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Set Azure Subscription
        run: |
          az account set --subscription "$AZURE_SUBSCRIPTION_ID"

      - name: Validate Bicep Templates
        run: |
          # Validates both Ubuntu and Windows templates
          
      - name: Deploy Ubuntu Server (VM1)
        run: |
          # Deploys Ubuntu infrastructure
          
      - name: Deploy Windows Server (VM2)
        run: |
          # Deploys Windows Server 2022
          
      - name: Deploy Azure Policies
        run: |
          # Applies governance policies
```

---

## Monitoring and Troubleshooting

- **Monitor Progress**: View workflow execution in the **Actions** tab of your GitHub repository
- **Deployment Names**: Each deployment is timestamped for easy tracking in Azure portal
- **Verbose Output**: All Azure CLI commands use `--verbose` flag for detailed logging
- **Validation**: Templates are validated before deployment to catch errors early

**Common Issues:**
- **Secret Missing**: Ensure all required secrets are configured in GitHub Actions
- **Permission Errors**: Verify service principal has Contributor role on subscription
- **Resource Conflicts**: Check for existing resources with same names in target resource group

---

## Post-Deployment Steps

After successful deployment:

1. **Ubuntu Server**: Ready for immediate use as Linux workstation
2. **Windows Server**: Run the following PowerShell configuration scripts:
   - `scripts/windows-server-entra-prereqs.ps1`
   - `scripts/windows-server-mdi-prereqs.ps1`
3. **Verify Resources**: Check Azure portal for all deployed resources
4. **Cost Control**: Confirm auto-shutdown policies are applied

---

## Manual Triggering

The workflow can also be triggered manually using the `workflow_dispatch` event:
1. Go to **Actions** tab in your repository
2. Select "Deploy Azure Lab Environment" workflow
3. Click "Run workflow" button
4. Choose the branch and click "Run workflow"
