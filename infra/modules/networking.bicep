// ============================================================================
// Networking Module
// ============================================================================
// Purpose: Virtual network and subnet configuration
// Dependencies: None

@description('Primary deployment region')
param location string

@description('Virtual network name')
param vnetName string

@description('Tags applied to all resources')
param tags object

// ============================================================================
// VIRTUAL NETWORK
// ============================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'compute'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'data'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnetIds object = {
  default: virtualNetwork.properties.subnets[0].id
  compute: virtualNetwork.properties.subnets[1].id
  data: virtualNetwork.properties.subnets[2].id
}
