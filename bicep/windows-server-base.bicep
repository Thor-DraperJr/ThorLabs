// windows-server-base.bicep - ThorLabs Windows Server 2022 Base Template
// Deploys a basic Windows Server 2022 VM with RDP access, public IP, and latest security features

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Virtual machine name following ThorLabs naming convention.')
@minLength(3)
@maxLength(64)
param vmName string = 'thorlabs-vm2-eastus2'

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
@allowed(['Standard_B2s', 'Standard_B4ms', 'Standard_DS2_v2', 'Standard_DS3_v2', 'Standard_D2s_v3', 'Standard_D4s_v3'])
param vmSize string = 'Standard_B2s'

@description('Allowed source IP addresses for RDP access. Restrict to specific IPs in production.')
param allowedSourceIPs array = ['0.0.0.0/0']

// Network Security Group for Windows Server with RDP access
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: 'thorlabs-nsg2-eastus2'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP-Access'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: allowedSourceIPs[0]
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: 'Allow RDP access - restrict source IPs in production'
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'thorlabs-vnet2-eastus2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.2.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.2.0.0/24'
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

// Windows Server 2022 Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
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
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: true
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
@description('VM Name')
output vmName string = vm.name

@description('VM Public IP Address')
output publicIPAddress string = publicIP.properties.ipAddress

@description('VM Admin Username')
output adminUsername string = adminUsername

@description('VM Resource ID')
output vmResourceId string = vm.id