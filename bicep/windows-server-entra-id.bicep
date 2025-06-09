// windows-server-entra-id.bicep
// Deploys a Windows Server 2022 VM for Entra ID Connect and Microsoft Defender for Identity

param location string = resourceGroup().location
param vmName string = 'thorlabs-vm2-eastus2'
param adminUsername string
@secure()
param adminPassword string
param vmSize string = 'Standard_D2s_v3' // Minimum recommended for domain services
param vnetAddressPrefix string = '10.1.0.0/16'
param subnetAddressPrefix string = '10.1.1.0/24'
param domainControllerIP string = '10.1.1.10'
param allowedSourceIPs array = ['0.0.0.0/0'] // Restrict to specific IPs in production
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param osDiskType string = 'Premium_LRS'
param osDiskSizeGB int = 128

// Network Security Group for Windows Server with restricted access
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP-Restricted'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: allowedSourceIPs[0] // TODO: Support multiple IPs
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: 'Allow RDP access - restrict source IPs in production'
        }
      }
      {
        name: 'WinRM-HTTP'
        properties: {
          priority: 1010
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16' // Restrict to VNet only
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5985'
          description: 'WinRM HTTP for PowerShell remoting within VNet'
        }
      }
      {
        name: 'WinRM-HTTPS'
        properties: {
          priority: 1020
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16' // Restrict to VNet only
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5986'
          description: 'WinRM HTTPS for secure PowerShell remoting within VNet'
        }
      }
      {
        name: 'LDAP'
        properties: {
          priority: 1030
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '389'
          description: 'LDAP for domain services'
        }
      }
      {
        name: 'LDAPS'
        properties: {
          priority: 1031
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '636'
          description: 'LDAPS for secure domain services'
        }
      }
      {
        name: 'DNS-TCP'
        properties: {
          priority: 1032
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '53'
          description: 'DNS TCP for domain services'
        }
      }
      {
        name: 'DNS-UDP'
        properties: {
          priority: 1033
          protocol: 'Udp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '53'
          description: 'DNS UDP for domain services'
        }
      }
      {
        name: 'Kerberos'
        properties: {
          priority: 1034
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.1.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '88'
          description: 'Kerberos for domain authentication'
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
      addressPrefixes: [ vnetAddressPrefix ]
    }
    subnets: [
      {
        name: 'domain-subnet'
        properties: {
          addressPrefix: subnetAddressPrefix
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
          privateIPAddress: domainControllerIP // Static IP for domain controller
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
          storageAccountType: osDiskType
        }
        diskSizeGB: osDiskSizeGB
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