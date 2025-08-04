# ThorLabs Bicep Patterns

Bicep template patterns following Azure MCP server best practices and ThorLabs conventions.

## Required Template Structure

```bicep
// Always include metadata and descriptions
@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Storage account name following ThorLabs naming convention')
param storageAccountName string = 'thorlabsst1eastus2'

@allowed(['Standard_LRS', 'Standard_GRS', 'Premium_LRS'])
@description('Storage account SKU')
param storageAccountSku string = 'Standard_LRS'

// Required tags for all resources
var commonTags = {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
}
```

## Storage Account Pattern

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  tags: commonTags
}
```

## Virtual Machine Pattern

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
  }
  tags: commonTags
}
```

## Parameter Validation Patterns

```bicep
// VM Size validation
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_D2s_v3'])
param vmSize string = 'Standard_B1s'

// Region validation
@allowed(['eastus', 'eastus2', 'westus2', 'centralus'])
param location string = 'eastus2'

// Secure parameters
@secure()
@description('Administrator password for VM')
param adminPassword string
```

## Output Patterns

```bicep
// Always include useful outputs
@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Storage account primary endpoint')
output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Virtual machine name')
output vmName string = vm.name

@description('VM resource ID')
output vmResourceId string = vm.id
```

## Resource Naming Examples

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Storage Account | `thorlabs{service}{number}{region}` | `thorlabsst1eastus2` |
| Virtual Machine | `thorlabs-{service}{number}-{region}` | `thorlabs-vm1-eastus2` |
| Key Vault | `thorlabs-{service}{number}-{region}` | `thorlabs-kv1-eastus2` |
| Resource Group | `thorlabs-{purpose}-rg` | `thorlabs-lab-rg` |
| Virtual Network | `thorlabs-{purpose}-vnet` | `thorlabs-lab-vnet` |
