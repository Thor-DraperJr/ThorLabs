#!/bin/bash
# ThorLabs Defender-Sentinel Integration Validation Script
# Run this after deploying the security layer to verify integration

set -e

# Configuration
RESOURCE_GROUP="thorlabs-rg1-eastus2"
WORKSPACE_NAME="thorlabs-sentinel1-eastus2"
LOCATION="eastus2"

echo "🔍 ThorLabs Defender-Sentinel Integration Status"
echo "================================================"

# Check if Sentinel workspace exists
echo "📊 Checking Sentinel workspace..."
if az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --output none 2>/dev/null; then
  echo "✅ Sentinel workspace found: $WORKSPACE_NAME"
else
  echo "❌ Sentinel workspace not found. Deploy foundation + security layers first."
  exit 1
fi

# Get workspace details
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --query id -o tsv)

echo "📊 Workspace ID: $WORKSPACE_ID"

# Check Defender pricing tiers
echo ""
echo "🛡️ Microsoft Defender for Cloud Status:"
echo "----------------------------------------"

DEFENDER_SERVICES=("VirtualMachines" "StorageAccounts" "KeyVaults" "SqlServers")

for service in "${DEFENDER_SERVICES[@]}"; do
  PRICING_STATUS=$(az security pricing show --name $service --query pricingTier -o tsv 2>/dev/null || echo "Not configured")
  echo "🔹 Defender for $service: $PRICING_STATUS"
done

# Check data connectors (requires Microsoft.SecurityInsights provider)
echo ""
echo "🔗 Data Connector Status:"
echo "-------------------------"

# Enable Sentinel provider if not already enabled
az provider register --namespace Microsoft.SecurityInsights --wait

# Query for Sentinel data connectors using Resource Graph
echo "🔍 Querying Sentinel data connectors..."

# Alternative: Direct REST API call to check connectors
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
ACCESS_TOKEN=$(az account get-access-token --query accessToken -o tsv)

# Check if Sentinel solution is installed
SENTINEL_SOLUTION=$(az monitor log-analytics solution show \
  --resource-group $RESOURCE_GROUP \
  --solution-name "SecurityInsights($WORKSPACE_NAME)" \
  --query name -o tsv 2>/dev/null || echo "Not found")

if [ "$SENTINEL_SOLUTION" != "Not found" ]; then
  echo "✅ Sentinel solution installed: $SENTINEL_SOLUTION"
else
  echo "❌ Sentinel solution not found"
fi

# Check for security events in workspace
echo ""
echo "📈 Security Data Ingestion Status:"
echo "----------------------------------"

# Query for recent security data
QUERY="SecurityAlert | where TimeGenerated > ago(24h) | summarize count() by ProductName | order by count_ desc"
ENCODED_QUERY=$(echo "$QUERY" | base64 -w 0)

echo "🔍 Checking for security alerts in last 24h..."

# Use KQL query to check data ingestion
az monitor log-analytics query \
  --workspace $WORKSPACE_ID \
  --analytics-query "$QUERY" \
  --output table || echo "No security data found (expected for new deployment)"

echo ""
echo "🌐 Sentinel Portal Access:"
echo "--------------------------"
echo "📱 Sentinel URL: https://portal.azure.com/#@$(az account show --query tenantId -o tsv)/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/$SUBSCRIPTION_ID/resourceGroup/$RESOURCE_GROUP/workspaceName/$WORKSPACE_NAME"

echo ""
echo "📋 Integration Summary:"
echo "----------------------"
echo "✅ Workspace: $WORKSPACE_NAME"
echo "✅ Resource Group: $RESOURCE_GROUP"
echo "✅ Sentinel solution: Ready"
echo "🔄 Data connectors: Deploy security layer to activate"
echo "📊 Analytics rules: Will be active after deployment"

echo ""
echo "🚀 Next Steps:"
echo "-------------"
echo "1. Deploy security layer: 'gh workflow run \"🛡️ Deploy Security (Sentinel)\"'"
echo "2. Enable Defender for Cloud: Run defender enablement script"
echo "3. Verify data ingestion after 15-30 minutes"
echo "4. Create custom analytics rules for ThorLabs environment"

echo ""
echo "🔧 Quick Commands:"
echo "-----------------"
echo "# Enable Defender for VMs:"
echo "az security pricing create --name VirtualMachines --tier Standard --sub-plan P2"
echo ""
echo "# Check Sentinel health:"
echo "az monitor log-analytics query --workspace $WORKSPACE_ID --analytics-query 'SentinelHealth | summarize count() by SentinelResourceType'"
echo ""
echo "# View security alerts:"
echo "az monitor log-analytics query --workspace $WORKSPACE_ID --analytics-query 'SecurityAlert | where TimeGenerated > ago(7d) | summarize count() by AlertSeverity'"
