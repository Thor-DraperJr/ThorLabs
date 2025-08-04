// lab.bicep - ThorLabs Azure Lab Environment
// Unified template deploying both Ubuntu and Windows Server VMs with shared networking
// Updated for Azure MCP compliance with latest API versions and security best practices

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Administrator username for both virtual machines.')
@minLength(3)
@maxLength(20)
param adminUsername string

@description('Administrator password for both virtual machines.')
@secure()
@minLength(12)
@maxLength(123)
param adminPassword string

@description('Virtual machine size for the Ubuntu VM.')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2', 'Standard_DS2_v2', 'Standard_D2s_v3'])
param ubuntuVmSize string = 'Standard_DS1_v2'

@description('Virtual machine size for the Windows Server VM.')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2', 'Standard_DS2_v2', 'Standard_D2s_v3'])
param windowsVmSize string = 'Standard_DS1_v2'

@description('SSH public key for Ubuntu VM authentication (optional).')
param sshPublicKey string = ''

// Shared Network Security Group with rules for both SSH and RDP
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: 'thorlabs-nsg1-eastus2'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH-Access'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          description: 'Allow SSH access for Ubuntu VM'
        }
      }
      {
        name: 'RDP-Access'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: 'Allow RDP access for Windows VM'
        }
      }
    ]
    flushConnection: false
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Shared Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'thorlabs-vnet1-eastus2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.10.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu VM Public IP
resource ubuntuPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'thorlabs-vm1-eastus2-pip'
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows VM Public IP
resource windowsPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'thorlabs-vm2-eastus2-pip'
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu VM Network Interface
resource ubuntuNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: 'thorlabs-vm1-eastus2-nic'
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
            id: ubuntuPublicIP.id
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows VM Network Interface
resource windowsNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: 'thorlabs-vm2-eastus2-nic'
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
            id: windowsPublicIP.id
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu Virtual Machine
resource ubuntuVM 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: 'thorlabs-vm1-eastus2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: ubuntuVmSize
    }
    osProfile: {
      computerName: 'thorlabs-vm1-eastus2'
      adminUsername: adminUsername
      adminPassword: !empty(sshPublicKey) ? null : adminPassword
      linuxConfiguration: !empty(sshPublicKey) ? {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      } : {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: 'thorlabs-vm1-eastus2-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ubuntuNic.id
          properties: {
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows Server 2022 Virtual Machine
resource windowsVM 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: 'thorlabs-vm2-eastus2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: windowsVmSize
    }
    osProfile: {
      computerName: 'THORLABS-WIN'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: 'Eastern Standard Time'
        patchSettings: {
          patchMode: 'AutomaticByOS'
          enableHotpatching: false
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        name: 'thorlabs-vm2-eastus2-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
          properties: {
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
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Outputs
@description('Name of the Ubuntu virtual machine')
output ubuntuVMName string = ubuntuVM.name

@description('Name of the Windows virtual machine')
output windowsVMName string = windowsVM.name

@description('Public IP address of the Ubuntu VM')
output ubuntuPublicIPAddress string = ubuntuPublicIP.properties.ipAddress

@description('Public IP address of the Windows VM')
output windowsPublicIPAddress string = windowsPublicIP.properties.ipAddress

@description('Administrator username for both VMs')
output adminUsername string = adminUsername

@description('Name of the virtual network')
output vnetName string = vnet.name

@description('Name of the default subnet')
output subnetName string = vnet.properties.subnets[0].name

@description('Name of the network security group')
output nsgName string = nsg.name

@description('Resource group location')
output location string = location

@description('Ubuntu VM resource ID')
output ubuntuVMId string = ubuntuVM.id

@description('Windows VM resource ID')
output windowsVMId string = windowsVM.id