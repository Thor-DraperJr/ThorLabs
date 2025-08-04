# GitHub Actions Workflow Troubleshooting Guide

## Common Issues and Solutions

### 1. Template Validation Failures

**Symptoms:**
- Workflows fail during Bicep template validation
- Error: "Missing required parameter"

**Causes & Solutions:**

#### Missing Azure AD Authentication Parameters
The updated templates require Azure AD authentication parameters. 

**Fix:** Add these secrets to your GitHub repository:
- `AZURE_AD_ADMIN_UPN` - Your Azure email (e.g., `user@domain.com`)
- `AZURE_AD_ADMIN_OBJECT_ID` - Your Azure AD object ID

**How to get these values:**
```bash
# Login to Azure
az login

# Get your identity information
./scripts/get-azure-identity.sh
```

**Add to GitHub:**
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add `AZURE_AD_ADMIN_UPN` with your email
4. Add `AZURE_AD_ADMIN_OBJECT_ID` with your object ID

#### Missing Required Secrets
**Fix:** Ensure these secrets are configured:
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

## Workflow Status Check

### Quick Diagnostic Steps
1. **Check secrets configuration:**
   - Go to repository Settings → Secrets and variables → Actions
   - Verify all required secrets are present

2. **Test basic Azure connectivity:**
   - Run the "ThorLabs Simple Test" workflow manually
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

### Advanced Troubleshooting

#### Enable Debug Logging
Add this to your workflow for more detailed logs:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

#### Check Azure Resource Logs
```bash
# List recent deployments
az deployment sub list --query "[?name contains 'thorlabs']"

# Get deployment details
az deployment sub show --name <deployment-name>
```

## Contact and Support

- Check the [Azure AD Authentication Guide](AZURE_AD_AUTHENTICATION.md)
- Review [GitHub Secrets Checklist](GITHUB_SECRETS_CHECKLIST.md)
- Validate templates with the latest Azure CLI and Bicep versions

## Fallback: Manual Deployment

If workflows continue to fail, you can deploy manually:
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
