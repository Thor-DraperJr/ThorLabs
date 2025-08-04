// ============================================================================
// ThorLabs Foundation Infrastructure (Layer 1)
// ============================================================================
// Purpose: Core infrastructure components that everything else depends on
// Deployment: Independent, can be deployed first
// Dependencies: None (foundation layer)

targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Primary deployment region')
param location string = 'eastus2'

@description('Environment designation for resource naming')
@allowed(['lab', 'dev', 'staging', 'prod'])
param environment string = 'lab'

@description('Project prefix for consistent naming')
param projectPrefix string = 'thorlabs'

@description('Resource group suffix for the lab environment')
param resourceGroupSuffix string = 'rg1'

@description('Tags applied to all resources')
param tags object = {
  Project: 'ThorLabs'
  Environment: environment
  Layer: 'Foundation'
  AutoShutdown_Time: '19:00'
  ManagedBy: 'Bicep'
}

// ============================================================================
// VARIABLES
// ============================================================================

var resourceGroupName = '${projectPrefix}-${resourceGroupSuffix}-${location}'
var keyVaultName = '${projectPrefix}-kv1-${location}'
var logAnalyticsName = '${projectPrefix}-logs1-${location}'
var vnetName = '${projectPrefix}-vnet1-${location}'

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ============================================================================
// NETWORKING MODULE
// ============================================================================

module networking 'modules/networking.bicep' = {
  name: 'networking-foundation'
  scope: resourceGroup
  params: {
    location: location
    vnetName: vnetName
    tags: tags
  }
}

// ============================================================================
// KEY VAULT MODULE  
// ============================================================================

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-foundation'
  scope: resourceGroup
  params: {
    location: location
    keyVaultName: keyVaultName
    tags: tags
  }
}

// ============================================================================
// LOG ANALYTICS MODULE
// ============================================================================

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logs-foundation'
  scope: resourceGroup
  params: {
    location: location
    workspaceName: logAnalyticsName
    tags: tags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultId string = keyVault.outputs.keyVaultId
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.workspaceName
output vnetId string = networking.outputs.vnetId
output vnetName string = networking.outputs.vnetName
output subnetIds object = networking.outputs.subnetIds
