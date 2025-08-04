// main.bicep - ThorLabs Simple Ubuntu VM Deployment
// Deploys a simple Ubuntu Server VM with latest Azure MCP standards

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Virtual machine name following ThorLabs naming convention.')
@minLength(3)
@maxLength(64)
param vmName string = 'thorlabs-vm1-eastus2'

@description('Administrator username for the virtual machine.')
@minLength(3)
@maxLength(20)
param adminUsername string

@description('Administrator password for the virtual machine.')
@secure()
@minLength(12)
@maxLength(123)
param adminPassword string

@description('Virtual machine size.')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2', 'Standard_DS2_v2', 'Standard_D2s_v3'])
param vmSize string = 'Standard_B1s'

@description('SSH public key for authentication (optional).')
param sshPublicKey string = ''

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'thorlabs-vnet1-eastus2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          defaultOutboundAccess: true
        }
      }
    ]
    enableDdosProtection: false
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Public IP Address
resource publicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    deleteOption: 'Delete'
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          primary: true
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: false
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Ubuntu Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        ssh: sshPublicKey != '' ? {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        } : null
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Auto-shutdown resource for VM
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'Eastern Standard Time'
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Outputs
@description('VM Admin Username')
output adminUsername string = adminUsername

@description('VM Public IP Address')
output vmPublicIP string = publicIP.properties.ipAddress

@description('VM Resource ID')
output vmResourceId string = vm.id
