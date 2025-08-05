# GitHub Actions: Complete Workflow Guide

## 🚀 Quick Start

### Automated Deployment (Recommended)
1. **Set up GitHub Actions secrets** - See [secrets checklist below](#required-secrets)
2. **Push to main branch** - Complete lab environment deploys automatically
3. **Monitor deployment** - Check GitHub Actions tab for real-time progress

### Manual Workflow Trigger
1. Go to **Actions** tab in your repository
2. Select "Deploy Azure Lab Environment" workflow  
3. Click "Run workflow" button
4. Choose the branch and click "Run workflow"

---

## 📋 Required Secrets

Configure these in **Settings → Actions → Secrets and variables → Actions**:

### Essential Secrets
- **`AZURE_SUBSCRIPTION_ID`** - Your Azure subscription ID
- **`ADMIN_PASSWORD`** - VM administrator password (used for both Ubuntu and Windows VMs)
- **`AZURE_CREDENTIALS`** - Service principal JSON for authentication

### Optional Secrets (For Azure AD Authentication)
- **`AZURE_AD_ADMIN_UPN`** - Your Azure email (e.g., `user@domain.com`)
- **`AZURE_AD_ADMIN_OBJECT_ID`** - Your Azure AD object ID

### How to Create Service Principal
```bash
export SUBSCRIPTION_ID=<your-subscription-id>
az ad sp create-for-rbac --name "thorlabs-sp-eastus2" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID --sdk-auth
```
Copy the JSON output and add it as the `AZURE_CREDENTIALS` secret.

### How to Get Azure Identity
```bash
# Get your identity information
./scripts/get-azure-identity.sh
```

---

## 🏗️ Deployment Workflow

The main deployment workflow (`deploy.yml`) automatically deploys:

### Resources Deployed
1. **Lab Environment** (`infra/lab.bicep`)
   - **Ubuntu Server VM** (`thorlabs-vm1-eastus2`) - General purpose Linux workstation
   - **Windows Server 2022 VM** (`thorlabs-vm2-eastus2`) - Windows Server with RDP access
   - **Shared VNet** (`thorlabs-lab-vnet`) - Single network (10.10.0.0/16) 
   - **Shared NSG** (`thorlabs-lab-nsg`) - Security group with SSH (22) and RDP (3389)
   - **Public IP addresses** - Dynamic IPs for both VMs
   - **Network interfaces** - Connected to shared subnet

2. **Azure Policy Definitions**
   - VM auto-shutdown enforcement (7pm ET shutdown tags)
   - Governance and compliance rules

### Workflow Steps
1. **Validation** - Validates Bicep templates before deployment
2. **Ubuntu Deployment** - Deploys Ubuntu server infrastructure  
3. **Windows Deployment** - Deploys Windows Server 2022
4. **Policy Deployment** - Applies Azure governance policies
5. **Summary Output** - Provides deployment results and next steps

---

## 📊 Monitoring & Failure Detection

The monitoring workflow (`monitor.yml`) provides automated failure detection:

### Purpose
- **Automatic Failure Detection** - Triggers when deploy workflow fails
- **Intelligent Issue Creation** - Creates detailed GitHub issues with failure context
- **Security-Conscious Logging** - Provides error summaries without exposing secrets
- **Streamlined Assignment** - Labels issues with `ci-failure` for review

### Issue Creation Details
When deployment fails, automatic GitHub issues include:
- **Workflow Run Link** - Direct link to failed execution
- **Branch and Commit** - Context about what triggered failure
- **Error Summary** - High-level summary of failed jobs
- **Next Steps** - Actionable troubleshooting guidance
- **Common Causes** - Reference to failure scenarios

### Security & Permissions
```yaml
permissions:
  issues: write      # Create GitHub issues for failed deployments
  actions: read      # Read workflow run details and logs
  contents: read     # Read repository contents (minimal access)
```

---

## 🔧 Troubleshooting Guide

### 1. Template Validation Failures

**Symptoms:**
- Workflows fail during Bicep template validation
- Error: "Missing required parameter"

**Solutions:**

#### Missing Azure AD Authentication Parameters
Add these secrets to your GitHub repository:
- `AZURE_AD_ADMIN_UPN` - Your Azure email
- `AZURE_AD_ADMIN_OBJECT_ID` - Your Azure AD object ID

```bash
# Get your identity information
az login
./scripts/get-azure-identity.sh
```

#### Missing Required Secrets
Ensure these secrets are configured:
- `AZURE_SUBSCRIPTION_ID`
- `ADMIN_PASSWORD` 
- `AZURE_CREDENTIALS`

### 2. Authentication Issues

**Symptoms:**
- "Azure login failed"
- "Invalid credentials"

**Solution:**
Recreate your service principal:
```bash
export SUBSCRIPTION_ID=<your-subscription-id>
az ad sp create-for-rbac --name "thorlabs-sp-eastus2" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID --sdk-auth
```
Copy the JSON output and update the `AZURE_CREDENTIALS` secret.

### 3. Deployment Timeouts

**Symptoms:**
- Workflow hangs during deployment
- Timeout errors

**Solutions:**
- Use smaller VM sizes: `Standard_B1s` instead of larger sizes
- Deploy in stages: core infrastructure first, then additional services
- Check Azure service limits in your region

### 4. Resource Naming Conflicts

**Symptoms:**
- "Resource name already exists"
- Deployment fails with naming conflicts

**Solutions:**
- Delete existing resource groups: `az group delete --name thorlabs-rg`
- Use unique resource group names
- Check for stuck deployments: `az deployment sub list`

---

## 🛠️ Advanced Troubleshooting

### Quick Diagnostic Steps
1. **Check secrets configuration:**
   - Go to repository Settings → Secrets and variables → Actions
   - Verify all required secrets are present

2. **Test basic Azure connectivity:**
   - Run workflows manually to test
   - Check Azure CLI version and subscription access

3. **Validate templates locally:**
   ```bash
   # Install Azure CLI and Bicep
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   az bicep install
   
   # Login and test compilation
   az login
   az bicep build --file infra/lab.bicep
   ```

### Enable Debug Logging
Add this to your workflow for detailed logs:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### Check Azure Resource Logs
```bash
# List recent deployments
az deployment sub list --query "[?name contains 'thorlabs']"

# Get deployment details
az deployment sub show --name <deployment-name>
```

---

## 🔄 Cleanup Workflow

The cleanup workflow (`cleanup-lab.yml`) provides safe environment deletion:

### Features
- **Manual triggering only** - Requires explicit user action
- **Confirmation required** - Users must type "DELETE" to confirm
- **Complete cleanup** - Removes `thorlabs-rg` resource group and all resources
- **Graceful handling** - Handles scenarios where resources don't exist

### How to Use
1. Go to **Actions** tab in your repository
2. Select "Cleanup Azure Lab Environment" workflow
3. Click "Run workflow" button
4. Type "DELETE" in the confirmation field
5. Click "Run workflow" to execute

---

## 💡 Best Practices

### For Repository Maintainers
- **Regular Review** - Monitor created issues for failure patterns
- **Documentation Updates** - Keep troubleshooting guides current
- **Access Control** - Ensure proper repository permissions

### For Developers
- **Issue Response** - Address `ci-failure` labeled issues promptly
- **Failure Analysis** - Use workflow run links for detailed debugging
- **Prevention** - Follow guidance in created issues to prevent recurring failures

### Security Guidelines
- **Never commit secrets** - Use GitHub Actions secrets only
- **Reference secrets safely** - Use `${{ secrets.SECRET_NAME }}`
- **Update documentation** - Keep checklists current as environment evolves

---

## 📚 Usage Examples

### Example Workflow YAML
```yaml
env:
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
  AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
  # Optional: For Azure AD authentication
  AZURE_AD_ADMIN_UPN: ${{ secrets.AZURE_AD_ADMIN_UPN }}
  AZURE_AD_ADMIN_OBJECT_ID: ${{ secrets.AZURE_AD_ADMIN_OBJECT_ID }}
```

### Fallback: Manual Deployment
If workflows continue to fail, deploy manually:
```bash
# Get your Azure identity
./scripts/get-azure-identity.sh

# Deploy manually
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters \
    adminUsername='thorlabsadmin' \
    adminPassword='YourSecurePassword123!' \
    enableAzureADAuth=true \
    azureADAdminUpn='your-email@domain.com' \
    azureADAdminObjectId='your-object-id'
```

---

## 📞 Integration Points

### Workflow Files
- **Deploy Workflow**: `.github/workflows/deploy.yml`
- **Monitor Workflow**: `.github/workflows/monitor.yml`
- **Cleanup Workflow**: `.github/workflows/cleanup-lab.yml`

### Related Documentation
- **Infrastructure Templates**: `infra/` directory
- **Deployment Scripts**: `scripts/deploy-lab.sh`
- **Project Overview**: `README.md`

---

*This guide consolidates all GitHub Actions workflow documentation for the ThorLabs environment. For infrastructure-specific details, see the main README.md and infra/ directory.*
