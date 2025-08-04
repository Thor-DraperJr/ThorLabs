// sentinel-security.bicep - ThorLabs Azure Sentinel Security Template
// Deploys Azure Sentinel with Log Analytics workspace and security solutions
// Updated for Azure MCP compliance with latest API versions and security best practices

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Log Analytics workspace name following ThorLabs naming convention.')
@minLength(4)
@maxLength(63)
param workspaceName string = 'thorlabs-sentinel-eastus2'

@description('Log Analytics workspace SKU.')
@allowed(['Free', 'Standard', 'Premium', 'PerNode', 'PerGB2018', 'Standalone', 'CapacityReservation'])
param workspaceSku string = 'PerGB2018'

@description('Log Analytics workspace data retention in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Daily quota for data ingestion in GB. Set to -1 for unlimited.')
param dailyQuotaGb int = 1

@description('Enable data export for the workspace.')
param enableDataExport bool = false

@description('Enable unified Sentinel billing.')
param unifiedSentinelBillingOnly bool = true

@description('Enable log access using only resource permissions.')
param enableLogAccessUsingOnlyResourcePermissions bool = true

// Log Analytics Workspace for Sentinel
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: workspaceSku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: enableLogAccessUsingOnlyResourcePermissions
      enableDataExport: enableDataExport
      unifiedSentinelBillingOnly: unifiedSentinelBillingOnly
      disableLocalAuth: false
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Security Operations'
    AutoShutdown_Time: '19:00'
  }
}

// Azure Sentinel Solution
resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
  location: location
  plan: {
    name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: []
    referencedResources: []
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Security Operations'
    AutoShutdown_Time: '19:00'
  }
}

// Security Events Solution (Optional - for Windows VM monitoring)
resource securityEventsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${logAnalyticsWorkspace.name})'
  location: location
  plan: {
    name: 'Security(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: []
    referencedResources: []
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Security Operations'
    AutoShutdown_Time: '19:00'
  }
}

// Container Insights Solution (Optional - for future container monitoring)
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalyticsWorkspace.name})'
  location: location
  plan: {
    name: 'ContainerInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: []
    referencedResources: []
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Security Operations'
    AutoShutdown_Time: '19:00'
  }
}

// Outputs
@description('Log Analytics Workspace Name')
output workspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics Workspace Resource ID')
output workspaceResourceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace Customer ID')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('Sentinel Solution Name')
output sentinelSolutionName string = sentinelSolution.name

@description('Log Analytics Workspace Location')
output workspaceLocation string = logAnalyticsWorkspace.location

@description('Workspace Primary Shared Key')
@secure()
output workspacePrimarySharedKey string = logAnalyticsWorkspace.listKeys().primarySharedKey

@description('Workspace Secondary Shared Key')
@secure()
output workspaceSecondarySharedKey string = logAnalyticsWorkspace.listKeys().secondarySharedKey
