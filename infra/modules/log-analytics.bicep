// ============================================================================
// Log Analytics Module
// ============================================================================
// Purpose: Centralized logging and monitoring workspace
// Dependencies: None

@description('Primary deployment region')
param location string

@description('Log Analytics workspace name')
param workspaceName string

@description('Tags applied to all resources')
param tags object

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
