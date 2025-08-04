// ============================================================================
// ThorLabs Compute Services (Layer 3)
// ============================================================================ 
// Purpose: Virtual machines and compute resources
// Deployment: Depends on Foundation and Security layers
// Dependencies: Resource Group, VNet, Key Vault, Log Analytics

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Primary deployment region')
param location string = resourceGroup().location

@description('Virtual network resource ID')
param vnetId string

@description('Subnet IDs from networking module')
param subnetIds object

@description('Key Vault name for secrets storage')
param keyVaultName string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('VM admin username')
param adminUsername string = 'thorlabsadmin'

@description('VM admin password')
@secure()
param adminPassword string

@description('Environment designation for resource naming')
@allowed(['lab', 'dev', 'staging', 'prod'])
param environment string = 'lab'

@description('Project prefix for consistent naming')
param projectPrefix string = 'thorlabs'

@description('Tags applied to all resources')
param tags object = {
  Project: 'ThorLabs'
  Environment: environment
  Layer: 'Compute'
  AutoShutdown_Time: '19:00'
  ManagedBy: 'Bicep'
}

// ============================================================================
// VARIABLES
// ============================================================================

var vmName = '${projectPrefix}-vm1-${location}'
var networkInterfaceName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'

// ============================================================================
// NETWORK SECURITY GROUP
// ============================================================================

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

// ============================================================================
// PUBLIC IP
// ============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// ============================================================================
// NETWORK INTERFACE
// ============================================================================

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetIds.default
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

// ============================================================================
// VIRTUAL MACHINE
// ============================================================================

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

// ============================================================================
// AUTO-SHUTDOWN CONFIGURATION
// ============================================================================

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900' // 7:00 PM
    }
    timeZoneId: 'Eastern Standard Time'
    targetResourceId: virtualMachine.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vmName string = virtualMachine.name
output vmId string = virtualMachine.id
output publicIpAddress string = publicIp.properties.ipAddress
output privateDnsName string = publicIp.properties.dnsSettings.fqdn
