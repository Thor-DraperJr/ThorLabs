// scripts-storage.bicep - ThorLabs Script Distribution Storage
// Storage account for script distribution to VMs in the ThorLabs environment with latest security features

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Storage account name following Azure naming conventions.')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'thorlabsst1eastus2'

@description('Container name for storing scripts.')
@minLength(3)
@maxLength(63)
param containerName string = 'scripts'

// Storage Account for script distribution
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
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
      requireInfrastructureEncryption: false
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    Purpose: 'Script Distribution'
  }
}

// Blob service for the storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Container for scripts
resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'VM script distribution'
      environment: 'ThorLabs'
      created: utcNow()
    }
  }
}

// Outputs
@description('Storage Account Name')
output storageAccountName string = storageAccount.name

@description('Storage Account Resource ID')
output storageAccountId string = storageAccount.id

@description('Scripts Container Name')
output scriptsContainerName string = scriptsContainer.name

@description('Scripts Container URI')
output scriptsContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'

@description('Storage Account Primary Access Key')
@secure()
output storageAccountKey string = storageAccount.listKeys().keys[0].value