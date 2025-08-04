// thorlabs-sentinel-simple.bicep - ThorLabs Lab Sentinel (Simplified)
// LAB/PLAYGROUND ENVIRONMENT: Clean, minimal Sentinel setup
// Focused on proper naming conventions and cost optimization

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Log Analytics workspace name following ThorLabs naming convention.')
param workspaceName string = 'thorlabs-sentinel1-eastus2'

@description('Workspace data retention in days (lab environment).')
@minValue(30)
@maxValue(90)
param retentionInDays int = 30

@description('Daily ingestion limit in GB for cost control.')
@minValue(1)
@maxValue(5)
param dailyQuotaGb int = 1

// Log Analytics Workspace for Sentinel
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Lab/Playground Security Operations Center'
    AutoShutdown_Time: '19:00'
    DataRetention: 'Low'
    CostOptimized: 'true'
    Service: 'Sentinel'
  }
}

// Security Insights (Sentinel) Solution
resource securityInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: []
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'Lab/Playground Security Operations Center'
    AutoShutdown_Time: '19:00'
    DataRetention: 'Low'
    CostOptimized: 'true'
    Service: 'Sentinel'
  }
}

// Outputs
@description('Log Analytics Workspace Name')
output workspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics Workspace Resource ID')
output workspaceResourceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace Customer ID')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('Sentinel Workspace URL')
output sentinelUrl string = 'https://portal.azure.com/#@${tenant().tenantId}/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/${subscription().subscriptionId}/resourceGroup/${resourceGroup().name}/workspaceName/${workspaceName}'

@description('Log Analytics Workspace Location')
output workspaceLocation string = logAnalyticsWorkspace.location

@description('Security Insights Solution Name')
output securityInsightsSolutionName string = securityInsights.name
