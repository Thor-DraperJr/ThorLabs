# ThorLabs Workflow Troubleshooting Guide

## 🔍 Common Workflow Failures & Solutions

### 1. Missing GitHub Secrets ❌
**Error**: "The workflow is requesting a secret that does not exist"

**Solution**: Add these secrets in your GitHub repository:
1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Add these secrets:

```
AZURE_SUBSCRIPTION_ID = "your-subscription-id-here"
ADMIN_PASSWORD = "your-secure-password-here"
AZURE_CREDENTIALS = {
  "clientId": "your-service-principal-client-id",
  "clientSecret": "your-service-principal-secret", 
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

### 2. Azure Authentication Failed ❌
**Error**: "Failed to login to Azure"

**Solution**: Create Azure Service Principal:
```bash
az ad sp create-for-rbac --name "thorlabs-github-actions" --role contributor --scopes /subscriptions/YOUR-SUBSCRIPTION-ID --sdk-auth
```

### 3. Resource Group Doesn't Exist ❌
**Error**: "Resource group 'thorlabs-rg' could not be found"

**Solution**: The workflow now auto-creates the resource group, but verify your subscription ID is correct.

### 4. Template Validation Failed ❌
**Error**: Various Bicep template errors

**Solution**: Run validation locally first:
```bash
az bicep build --file infra/lab.bicep
az deployment group validate --resource-group thorlabs-rg --template-file infra/lab.bicep --parameters @infra/lab.parameters.json
```

## 🛠️ Quick Fix Steps

1. **Check GitHub Secrets**: Repository Settings → Secrets and variables → Actions
2. **Test Azure CLI locally**: `az account show`
3. **Validate templates locally**: `az bicep build --file infra/lab.bicep`
4. **Use validation-only mode**: Set `validation_only: true` in workflow dispatch

## 🚀 Testing Strategy

### Safe Testing Approach:
1. **Start with validation only**: `validation_only: true`
2. **Check logs in VS Code**: GitHub Actions extension
3. **Fix any validation errors**: Update templates as needed
4. **Then deploy**: `validation_only: false`

### Quick Test Command:
Use the Quick Test workflow for faster iteration:
```yaml
# Triggers: .github/workflows/quick-test.yml
# Options: all, compilation, validation, what-if
```

## 📞 Need Help?

Common error patterns:
- **401 Unauthorized**: Check Azure credentials
- **403 Forbidden**: Check Azure permissions  
- **404 Not Found**: Check resource names/locations
- **Template errors**: Check Bicep syntax and parameters
