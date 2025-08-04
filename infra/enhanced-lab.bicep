// enhanced-lab.bicep - Comprehensive ThorLabs Azure Lab Environment
// Enhanced version with additional stable services for comprehensive testing
// Following Azure MCP best practices and ThorLabs conventions

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Administrator username for virtual machines.')
@minLength(3)
@maxLength(20)
param adminUsername string

@description('Administrator password for virtual machines (required for Windows, optional for Ubuntu if SSH key provided).')
@secure()
@minLength(12)
@maxLength(123)
param adminPassword string = 'TempPassword123!'

@description('SSH public key for Ubuntu VM authentication. If provided, password authentication is disabled for Ubuntu.')
param sshPublicKey string = ''

@description('Enable Azure AD login for VMs (requires Azure AD DS or Azure Arc). When enabled, you can login with your Azure identity.')
param enableAzureADLogin bool = false

@description('Virtual machine size for Ubuntu VM.')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2'])
param ubuntuVmSize string = 'Standard_B1s'

@description('Virtual machine size for Windows Server VM.')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2'])
param windowsVmSize string = 'Standard_B1s'

@description('Enable monitoring and analytics workspace.')
param enableMonitoring bool = true

@description('Enable storage account for lab artifacts.')
param enableStorage bool = true

@description('Enable Key Vault for secure secrets management.')
param enableKeyVault bool = true

@description('Enable Sentinel for security monitoring.')
param enableSentinel bool = false

@description('Deployment timestamp for resource tagging.')
param deploymentTimestamp string = utcNow('yyyy-MM-dd')

// Common variables
var projectName = 'thorlabs'
var regionCode = 'eastus2'
var commonTags = {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
  CreatedBy: 'IaC-Bicep'
  LastModified: deploymentTimestamp
}

// === NETWORKING ===
// Network Security Group with comprehensive rules
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${projectName}-nsg1-${regionCode}'
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
      {
        name: 'HTTP-Access'
        properties: {
          priority: 1002
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          description: 'Allow HTTP for web testing'
        }
      }
      {
        name: 'HTTPS-Access'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow HTTPS for web testing'
        }
      }
    ]
    flushConnection: false
  }
  tags: commonTags
}

// Virtual Network with enhanced configuration
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: '${projectName}-vnet1-${regionCode}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.10.0.0/16']
    }
    subnets: [
      {
        name: 'compute-subnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          defaultOutboundAccess: true
        }
      }
      {
        name: 'services-subnet'
        properties: {
          addressPrefix: '10.10.2.0/24'
          defaultOutboundAccess: true
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
    ]
    enableDdosProtection: false
  }
  tags: commonTags
}

// === LOG ANALYTICS & MONITORING ===
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (enableMonitoring) {
  name: '${projectName}-logs1-${regionCode}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
  tags: commonTags
}

// === AZURE SENTINEL ===
// Sentinel solution deployment
resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableSentinel && enableMonitoring) {
  name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
  location: location
  plan: {
    name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  tags: commonTags
}

// === STORAGE ===
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = if (enableStorage) {
  name: '${projectName}st1${regionCode}'
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
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      keySource: 'Microsoft.Storage'
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
    }
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: vnet.properties.subnets[1].id
          action: 'Allow'
        }
      ]
      ipRules: []
    }
  }
  tags: commonTags
}

// Storage containers for lab artifacts
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = if (enableStorage) {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = if (enableStorage) {
  parent: blobServices
  name: 'scripts'
  properties: {
    publicAccess: 'None'
  }
}

resource artifactsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = if (enableStorage) {
  parent: blobServices
  name: 'artifacts'
  properties: {
    publicAccess: 'None'
  }
}

// === KEY VAULT ===
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = if (enableKeyVault) {
  name: '${projectName}-kv1-${regionCode}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: vnet.properties.subnets[1].id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
      ipRules: []
    }
  }
  tags: commonTags
}

// Store admin credentials in Key Vault
resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = if (enableKeyVault) {
  parent: keyVault
  name: 'vm-admin-password'
  properties: {
    value: adminPassword
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// === VIRTUAL MACHINES ===
// Ubuntu VM Public IP
resource ubuntuPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${projectName}-vm1-${regionCode}-pip'
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
  tags: commonTags
}

// Windows VM Public IP
resource windowsPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${projectName}-vm2-${regionCode}-pip'
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
  tags: commonTags
}

// Ubuntu VM Network Interface
resource ubuntuNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: '${projectName}-vm1-${regionCode}-nic'
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
  tags: commonTags
}

// Windows VM Network Interface
resource windowsNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: '${projectName}-vm2-${regionCode}-nic'
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
  tags: commonTags
}

// Ubuntu Virtual Machine
resource ubuntuVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: '${projectName}-vm1-${regionCode}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: ubuntuVmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: '${projectName}-vm1'
      adminUsername: adminUsername
      adminPassword: empty(sshPublicKey) ? adminPassword : null
      linuxConfiguration: empty(sshPublicKey) ? null : {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: commonTags

  // Azure VM Extensions for monitoring
  resource vmExtensionOMS 'extensions@2024-07-01' = if (enableMonitoring) {
    name: 'OmsAgentForLinux'
    properties: {
      publisher: 'Microsoft.EnterpriseCloud.Monitoring'
      type: 'OmsAgentForLinux'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      settings: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
      }
      protectedSettings: {
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Windows Virtual Machine
resource windowsVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: '${projectName}-vm2-${regionCode}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: windowsVmSize
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
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: '${projectName}-vm2'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: commonTags

  // Azure VM Extensions for monitoring
  resource vmExtensionOMS 'extensions@2024-07-01' = if (enableMonitoring) {
    name: 'MicrosoftMonitoringAgent'
    properties: {
      publisher: 'Microsoft.EnterpriseCloud.Monitoring'
      type: 'MicrosoftMonitoringAgent'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      settings: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
      }
      protectedSettings: {
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// === OUTPUTS ===
output resourceGroupName string = resourceGroup().name
output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
output computeSubnetId string = vnet.properties.subnets[0].id
output servicesSubnetId string = vnet.properties.subnets[1].id
output ubuntuVmName string = ubuntuVM.name
output windowsVmName string = windowsVM.name
output ubuntuPublicIP string = ubuntuPublicIP.properties.ipAddress
output windowsPublicIP string = windowsPublicIP.properties.ipAddress
output storageAccountName string = enableStorage ? storageAccount.name : ''
output keyVaultName string = enableKeyVault ? keyVault.name : ''
output logAnalyticsWorkspaceName string = enableMonitoring ? logAnalyticsWorkspace.name : ''
output logAnalyticsWorkspaceId string = enableMonitoring ? logAnalyticsWorkspace.id : ''
output sentinelEnabled string = enableSentinel ? 'Enabled' : 'Disabled'
output sshCommand string = 'ssh ${adminUsername}@${ubuntuPublicIP.properties.ipAddress}'
output rdpCommand string = 'mstsc /v:${windowsPublicIP.properties.ipAddress}'
