// ============================================================================
// ThorLabs Security Services (Layer 2)  
// ============================================================================
// Purpose: Security monitoring and compliance services
// Deployment: Depends on Foundation layer
// Dependencies: Resource Group, Log Analytics Workspace

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Primary deployment region')
param location string = resourceGroup().location

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Environment designation for resource naming')
@allowed(['lab', 'dev', 'staging', 'prod'])
param environment string = 'lab'

@description('Project prefix for consistent naming')
param projectPrefix string = 'thorlabs'

@description('Tags applied to all resources')
param tags object = {
  Project: 'ThorLabs'
  Environment: environment
  Layer: 'Security'
  AutoShutdown_Time: '19:00'
  ManagedBy: 'Bicep'
}

// ============================================================================
// VARIABLES
// ============================================================================

var sentinelSolutionName = 'SecurityInsights(${logAnalyticsWorkspaceName})'

// ============================================================================
// MICROSOFT SENTINEL
// ============================================================================

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: sentinelSolutionName
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspaceId
  }
  plan: {
    name: sentinelSolutionName
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

// ============================================================================
// SECURITY DATA CONNECTORS (Basic Lab Setup)
// ============================================================================

// Note: Data connectors are typically configured through the Sentinel portal
// or via REST API after deployment. Bicep support is limited.
// This placeholder can be extended with custom deployment scripts if needed.

// ============================================================================
// OUTPUTS
// ============================================================================

output sentinelWorkspaceId string = logAnalyticsWorkspaceId
output sentinelSolutionId string = sentinelSolution.id
