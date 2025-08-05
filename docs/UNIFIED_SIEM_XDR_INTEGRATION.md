# Microsoft Defender XDR + Sentinel Unified Integration

## What You're Seeing in the Portal

The Microsoft Defender portal (security.microsoft.com) is offering to **"Connect a workspace"** - this is exactly the programmatic integration we can set up for your ThorLabs environment!

## Unified SIEM + XDR Integration

### 1. **Automatic Workspace Connection** (Click "Connect a workspace")
This connects your Sentinel workspace to the unified Defender portal:

```bash
# Enable unified security operations
az security workspace-setting create \
  --name default \
  --scope "/subscriptions/{subscription-id}" \
  --workspace-id "/subscriptions/{subscription-id}/resourceGroups/thorlabs-rg1-eastus2/providers/Microsoft.OperationalInsights/workspaces/thorlabs-sentinel1-eastus2"
```

### 2. **Programmatic Bicep Integration** 
Add to your security layer for automatic connection:

```bicep
// Microsoft 365 Defender Connector (XDR Integration)
resource m365DefenderConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-m365defender-${environment}'
  kind: 'MicrosoftThreatIntelligence'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      bingSafetyPhishingURL: {
        state: 'Enabled'
        lookbackPeriod: 'All'
      }
      microsoftEmergingThreatFeed: {
        state: 'Enabled'
        lookbackPeriod: 'All'
      }
    }
  }
}

// Microsoft Defender XDR Integration
resource defenderXDRConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-defender-xdr-${environment}'
  kind: 'MicrosoftThreatProtection'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      incidents: {
        state: 'Enabled'
      }
      alerts: {
        state: 'Enabled'
      }
    }
  }
}

// Unified Security Operations Configuration
resource unifiedSecuritySettings 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}
```

### 3. **PowerShell Script for Portal Integration**

```powershell
# Connect ThorLabs Sentinel to Unified Defender Portal
$TenantId = (Get-AzContext).Tenant.Id
$SubscriptionId = (Get-AzContext).Subscription.Id
$WorkspaceResourceId = "/subscriptions/$SubscriptionId/resourceGroups/thorlabs-rg1-eastus2/providers/Microsoft.OperationalInsights/workspaces/thorlabs-sentinel1-eastus2"

# Enable Sentinel in Defender portal
Set-AzSecurityWorkspaceSetting -Name 'default' -WorkspaceId $WorkspaceResourceId -Scope "/subscriptions/$SubscriptionId"

# Enable Microsoft 365 Defender integration
$ConnectorBody = @{
    kind = "MicrosoftThreatIntelligence"
    properties = @{
        tenantId = $TenantId
        dataTypes = @{
            microsoftEmergingThreatFeed = @{
                state = "Enabled"
                lookbackPeriod = "All"
            }
        }
    }
} | ConvertTo-Json -Depth 5

# REST API call to create connector
$Headers = @{
    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
    'Content-Type' = 'application/json'
}

$ConnectorUri = "https://management.azure.com$WorkspaceResourceId/providers/Microsoft.SecurityInsights/dataConnectors/thorlabs-m365defender?api-version=2023-02-01"
Invoke-RestMethod -Uri $ConnectorUri -Method PUT -Body $ConnectorBody -Headers $Headers
```

### 4. **Automated Connection Script**

```bash
#!/bin/bash
# ThorLabs Unified Security Operations Setup

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
RESOURCE_GROUP="thorlabs-rg1-eastus2"
WORKSPACE_NAME="thorlabs-sentinel1-eastus2"

echo "🔗 Connecting ThorLabs Sentinel to Unified Defender Portal..."

# Get workspace resource ID
WORKSPACE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME"

# Enable unified security operations
az security workspace-setting create \
  --name default \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --workspace-id "$WORKSPACE_ID"

echo "✅ ThorLabs Sentinel connected to Defender portal!"
echo "🌐 Access unified portal: https://security.microsoft.com"
echo "📊 Sentinel data will appear in Defender XDR within 15-30 minutes"

# Enable Microsoft 365 Defender data sharing
echo "🔄 Enabling Microsoft 365 Defender integration..."

# Create the M365 Defender connector
cat > connector_payload.json << EOF
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

# Apply the connector
az rest \
  --method PUT \
  --url "https://management.azure.com${WORKSPACE_ID}/providers/Microsoft.SecurityInsights/dataConnectors/thorlabs-m365defender?api-version=2023-02-01" \
  --body @connector_payload.json

rm connector_payload.json

echo "🎯 Integration Complete!"
echo "📱 Unified Portal: https://security.microsoft.com"
echo "🛡️ Sentinel Portal: https://portal.azure.com/#@$TENANT_ID/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/$SUBSCRIPTION_ID/resourceGroup/$RESOURCE_GROUP/workspaceName/$WORKSPACE_NAME"
```

## Benefits of Unified SIEM + XDR

### **What This Integration Provides:**

1. **Single Pane of Glass**: 
   - All security data in one portal (security.microsoft.com)
   - Unified incident management
   - Cross-platform threat hunting

2. **Enhanced AI & Automation**:
   - Microsoft Copilot for Security integration
   - Automated response across Defender + Sentinel
   - Advanced threat intelligence correlation

3. **Streamlined Workflows**:
   - No context switching between portals
   - Unified investigation experience
   - Consistent alerting and reporting

4. **Cost Optimization**:
   - Unified billing for Defender + Sentinel
   - Optimized data ingestion
   - Reduced operational overhead

## ThorLabs Implementation Steps

### **Immediate Actions:**

1. **Click "Connect a workspace" in your Defender portal**
2. **Select your ThorLabs Sentinel workspace**
3. **Run the automated connection script above**

### **Enhanced Security Layer Deployment:**

```bash
# Deploy enhanced security layer with unified integration
gh workflow run "🛡️ Deploy Security (Sentinel)" 

# Then run the connection script
./scripts/connect-unified-security.sh
```

### **Validation Commands:**

```bash
# Check if workspace is connected
az security workspace-setting show --name default

# Verify data connectors
az monitor log-analytics query \
  --workspace thorlabs-sentinel1-eastus2 \
  --analytics-query "ThreatIntelligenceIndicator | where TimeGenerated > ago(24h) | summarize count() by SourceSystem"

# Check unified portal access
echo "🌐 Unified Security Portal: https://security.microsoft.com"
```

## Next Steps After Connection

Once connected, you'll have:
- **📊 ThorLabs incidents** appearing in the unified Defender portal
- **🔍 Cross-platform hunting** across your entire security stack  
- **🤖 AI-powered insights** from Microsoft Copilot for Security
- **⚡ Automated response** workflows spanning Defender + Sentinel

The portal you're seeing is the future of security operations - unified SIEM and XDR in one place! 🚀
