#!/bin/bash
# get-azure-identity.sh - Get your Azure AD identity information for passwordless authentication

set -e

echo "🔍 Getting your Azure AD identity information..."
echo

# Check if logged in to Azure
if ! az account show >/dev/null 2>&1; then
    echo "❌ You need to login to Azure first:"
    echo "   az login"
    echo
    exit 1
fi

# Get current user information
echo "📋 Current Azure Account:"
ACCOUNT_INFO=$(az account show --query '{subscriptionId:id,subscriptionName:name,userPrincipalName:user.name,userType:user.type}' -o table)
echo "$ACCOUNT_INFO"
echo

# Get user object ID and UPN
USER_UPN=$(az account show --query user.name -o tsv)
echo "📧 Your User Principal Name (UPN): $USER_UPN"

# Get object ID
echo "🔍 Looking up your Object ID..."
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
echo "🆔 Your Object ID: $USER_OBJECT_ID"
echo

# Show tenant information
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "🏢 Tenant ID: $TENANT_ID"
echo

echo "✅ Use these values when deploying with Azure AD authentication:"
echo
echo "azureADAdminUpn: '$USER_UPN'"
echo "azureADAdminObjectId: '$USER_OBJECT_ID'"
echo

echo "📋 Example deployment command:"
echo "az deployment sub create \\"
echo "  --location eastus2 \\"
echo "  --template-file infra/master-deployment.bicep \\"
echo "  --parameters \\"
echo "    adminUsername='thorlabsadmin' \\"
echo "    enableAzureADAuth=true \\"
echo "    azureADAdminUpn='$USER_UPN' \\"
echo "    azureADAdminObjectId='$USER_OBJECT_ID'"
echo

echo "🔑 Benefits of Azure AD authentication:"
echo "- No passwords to manage"
echo "- Use your existing Azure identity"
echo "- Enhanced security with MFA support"
echo "- Centralized access management"
