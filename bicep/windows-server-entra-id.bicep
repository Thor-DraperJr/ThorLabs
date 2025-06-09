// windows-server-entra-id.bicep
// Deploys a Windows Server 2022 VM for Entra ID Connect and Microsoft Defender for Identity

param location string = resourceGroup().location
param vmName string = 'thorlabs-vm2-eastus2'
param adminUsername string
@secure()
param adminPassword string
param vmSize string = 'Standard_D2s_v3' // Minimum recommended for domain services

// Network Security Group for Windows Server
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
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
      {
        name: 'WinRM'
        properties: {
          priority: 1010
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5985'
        }
      }
      {
        name: 'WinRM-HTTPS'
        properties: {
          priority: 1020
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5986'
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'EntraID-MDI'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Virtual Network (reuse existing or create new subnet)
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.1.0.0/16' ]
    }
    subnets: [
      {
        name: 'domain-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
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
    Purpose: 'EntraID-MDI'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Public IP for RDP access
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${vmName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id)}')
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'EntraID-MDI'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
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
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.1.10' // Static IP for domain controller
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'EntraID-MDI'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
}

// Windows Server 2022 Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'THORLABS-DC01'
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
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    Purpose: 'EntraID-MDI'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
    Role: 'DomainController'
    Services: 'EntraIDConnect,MDI'
  }
}

// Custom Script Extension to run initial setup
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: 'CustomScriptExtension'
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "Set-TimeZone -Id \'Eastern Standard Time\'; Enable-PSRemoting -Force; Set-NetFirewallRule -DisplayGroup \'Windows Remote Management\' -Enabled True"'
    }
  }
}

// Outputs
output vmName string = vm.name
output publicIPAddress string = publicIP.properties.ipAddress
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output rdpConnectionString string = '${publicIP.properties.dnsSettings.fqdn}:3389'
output resourceGroupName string = resourceGroup().name