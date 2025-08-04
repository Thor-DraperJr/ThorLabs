// thorlabs-storage.bicep
// Secure storage account for ThorLabs lab environment
// Generated following Azure MCP server best practices

@description('Location for all resources')
param location string = resourceGroup().location

@description('Storage account name following ThorLabs naming convention')
param storageAccountName string = 'thorlabsst2eastus2'

@description('Storage account SKU - cost-optimized for lab use')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS'])
param sku string = 'Standard_LRS'

@description('Storage account access tier - optimized for lab workloads')
@allowed(['Hot', 'Cool'])
param accessTier string = 'Hot'

@description('Minimum TLS version for security compliance')
@allowed(['TLS1_2', 'TLS1_3'])
param minimumTlsVersion string = 'TLS1_2'

// Storage Account following Azure best practices
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  properties: {
    // Security configurations per Azure best practices
    accessTier: accessTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true // Simplified for lab environment
    allowCrossTenantReplication: false
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: true
    
    // Encryption at rest (enabled by default)
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    
    // Network access configuration for lab environment
    networkAcls: {
      defaultAction: 'Allow' // Simplified for lab - restrict in production
    }
  }
  
  // Required ThorLabs tags for cost control and governance
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
    Purpose: 'General Storage'
  }
}

// Blob service with retention policy
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7 // Cost-effective retention for lab environment
    }
    isVersioningEnabled: false // Disabled for cost optimization
  }
}

// Optional: Scripts container for VM automation
resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobService
  name: 'scripts'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'VM automation scripts'
      environment: 'ThorLabs'
    }
  }
}

// Outputs for consumption by other templates or scripts
@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Storage account ID')
output storageAccountId string = storageAccount.id

@description('Primary blob endpoint')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Scripts container name')
output scriptsContainerName string = scriptsContainer.name

@description('Storage account access keys (use carefully)')
output storageAccountKeys object = {
  key1: storageAccount.listKeys().keys[0].value
  key2: storageAccount.listKeys().keys[1].value
}
