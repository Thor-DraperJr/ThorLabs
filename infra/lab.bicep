// lab.bicep
// Unified template deploying both Ubuntu and Windows Server VMs with shared networking

param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string

// Shared Network Security Group with rules for both SSH and RDP
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'thorlabs-lab-nsg'
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
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Shared Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'thorlabs-lab-vnet'
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
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu VM Public IP
resource ubuntuPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'thorlabs-vm1-eastus2-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows VM Public IP
resource windowsPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'thorlabs-vm2-eastus2-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu VM Network Interface
resource ubuntuNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
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
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows VM Network Interface
resource windowsNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
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
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Ubuntu Virtual Machine
resource ubuntuVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'thorlabs-vm1-eastus2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: 'thorlabs-vm1-eastus2'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ubuntuNic.id
        }
      ]
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
resource windowsVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'thorlabs-vm2-eastus2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'THORLABS-WIN'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: 'Eastern Standard Time'
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
        }
      ]
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
output ubuntuVMName string = ubuntuVM.name
output windowsVMName string = windowsVM.name
output ubuntuPublicIPAddress string = ubuntuPublicIP.properties.ipAddress
output windowsPublicIPAddress string = windowsPublicIP.properties.ipAddress
output adminUsername string = adminUsername
output vnetName string = vnet.name
output subnetName string = vnet.properties.subnets[0].name
output nsgName string = nsg.name