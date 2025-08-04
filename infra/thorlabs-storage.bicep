// thorlabs-storage.bicep
// Storage account template following ThorLabs patterns and Azure MCP server best practices

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Storage account name following ThorLabs naming convention')
param storageAccountName string = 'thorlabsst1eastus2'

@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS', 'Premium_LRS'])
@description('Storage account SKU for performance and redundancy')
param storageAccountSku string = 'Standard_LRS'

@allowed(['Hot', 'Cool'])
@description('Storage access tier for cost optimization')
param accessTier string = 'Hot'

@description('Container name for scripts storage')
param containerName string = 'scripts'

// Required tags for all ThorLabs resources
var commonTags = {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
  Purpose: 'Lab Storage'
}

// Storage Account with security best practices from Azure MCP guidance
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    // Security settings following Azure best practices
    accessTier: accessTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true  // Enabled for lab environment simplicity
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    
    // Encryption configuration
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
    
    // Network access rules for lab environment
    networkAcls: {
      defaultAction: 'Allow'  // Simplified for lab access
      bypass: 'AzureServices'
    }
  }
  tags: commonTags
}

// Blob service configuration
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Container for script distribution
resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'VM script distribution'
      environment: 'ThorLabs Lab'
    }
  }
}

// Outputs for integration with other templates
@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Storage account resource ID')
output storageAccountId string = storageAccount.id

@description('Primary blob endpoint')
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Scripts container name')
output scriptsContainerName string = scriptsContainer.name

@description('Scripts container URI')
output scriptsContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'

@description('Storage account connection string (for lab use)')
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
