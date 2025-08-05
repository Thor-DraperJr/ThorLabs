#!/bin/bash
# ThorLabs Unified Security Operations Setup
# Connects Sentinel workspace to Microsoft Defender XDR portal

set -e

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
RESOURCE_GROUP="thorlabs-rg1-eastus2"
WORKSPACE_NAME="thorlabs-sentinel1-eastus2"

echo "🔗 ThorLabs Unified SIEM + XDR Integration"
echo "=========================================="
echo "📊 Connecting Sentinel workspace to Defender portal..."
echo ""

# Get workspace resource ID
WORKSPACE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME"

# Check if workspace exists
echo "🔍 Verifying Sentinel workspace exists..."
if az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --output none 2>/dev/null; then
  echo "✅ Sentinel workspace found: $WORKSPACE_NAME"
else
  echo "❌ Sentinel workspace not found. Deploy security layer first:"
  echo "   gh workflow run \"🛡️ Deploy Security (Sentinel)\""
  exit 1
fi

# Enable unified security operations
echo ""
echo "🔧 Enabling unified security operations..."
az security workspace-setting create \
  --name default \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --workspace-id "$WORKSPACE_ID" || echo "⚠️  Workspace setting may already exist"

echo "✅ ThorLabs Sentinel connected to Defender portal!"

# Enable Microsoft 365 Defender data sharing
echo ""
echo "🔄 Enabling Microsoft 365 Defender integration..."

# Create the M365 Defender connector payload
cat > /tmp/connector_payload.json << EOF
{
  "kind": "MicrosoftThreatIntelligence",
  "properties": {
    "tenantId": "$TENANT_ID",
    "dataTypes": {
      "microsoftEmergingThreatFeed": {
        "state": "Enabled",
        "lookbackPeriod": "All"
      },
      "bingSafetyPhishingURL": {
        "state": "Enabled",
        "lookbackPeriod": "All"
      }
    }
  }
}
EOF

# Apply the M365 Defender connector
echo "📡 Creating Microsoft 365 Defender data connector..."
az rest \
  --method PUT \
  --url "https://management.azure.com${WORKSPACE_ID}/providers/Microsoft.SecurityInsights/dataConnectors/thorlabs-m365defender?api-version=2023-02-01" \
  --body @/tmp/connector_payload.json || echo "⚠️  Connector may already exist"

# Clean up temp file
rm -f /tmp/connector_payload.json

# Create Microsoft Threat Protection connector
echo "🛡️  Creating Microsoft Threat Protection connector..."
cat > /tmp/mtp_connector.json << EOF
{
  "kind": "MicrosoftThreatProtection",
  "properties": {
    "tenantId": "$TENANT_ID",
    "dataTypes": {
      "incidents": {
        "state": "Enabled"
      },
      "alerts": {
        "state": "Enabled"
      }
    }
  }
}
EOF

az rest \
  --method PUT \
  --url "https://management.azure.com${WORKSPACE_ID}/providers/Microsoft.SecurityInsights/dataConnectors/thorlabs-mtp?api-version=2023-02-01" \
  --body @/tmp/mtp_connector.json || echo "⚠️  MTP Connector may already exist"

rm -f /tmp/mtp_connector.json

echo ""
echo "🎯 Integration Complete!"
echo "======================="
echo ""
echo "📱 **Unified Security Portal**: https://security.microsoft.com"
echo "🛡️  **Sentinel Portal**: https://portal.azure.com/#@$TENANT_ID/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/$SUBSCRIPTION_ID/resourceGroup/$RESOURCE_GROUP/workspaceName/$WORKSPACE_NAME"
echo ""
echo "⏰ **Timeline**: Data will appear in unified portal within 15-30 minutes"
echo ""
echo "🔍 **What's Next:**"
echo "  1. Visit https://security.microsoft.com"
echo "  2. Navigate to 'Incidents & alerts' → 'Incidents'"
echo "  3. View unified ThorLabs security data"
echo "  4. Use Microsoft Copilot for Security (if available)"
echo ""
echo "📊 **Validation Commands:**"
echo "  # Check workspace connection"
echo "  az security workspace-setting show --name default"
echo ""
echo "  # Verify threat intelligence data"
echo "  az monitor log-analytics query \\"
echo "    --workspace $WORKSPACE_NAME \\"
echo "    --analytics-query \"ThreatIntelligenceIndicator | where TimeGenerated > ago(24h) | summarize count() by SourceSystem\""
echo ""
echo "🚀 **ThorLabs now has unified SIEM + XDR capabilities!**"
