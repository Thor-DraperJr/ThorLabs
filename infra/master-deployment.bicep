// master-deployment.bicep - Complete ThorLabs Azure Lab Environment
// Orchestrates deployment of all lab services using modular Bicep templates
// Following Azure MCP best practices and ThorLabs conventions

targetScope = 'subscription'

@description('The Azure region where resources will be deployed.')
param location string = 'eastus2'

@description('Administrator username for all services.')
@minLength(3)
@maxLength(20)
param adminUsername string

@description('Administrator password for services (optional if using Azure AD auth).')
@secure()
@minLength(12)
@maxLength(123)
param adminPassword string = 'TempPassword123!'

@description('SSH public key for Ubuntu VM authentication. If provided, password auth is disabled for Ubuntu.')
param sshPublicKey string = ''

@description('Enable Azure AD authentication for databases and services.')
param enableAzureADAuth bool = true

@description('Your Azure AD user principal name (email) for admin access.')
param azureADAdminUpn string = ''

@description('Your Azure AD user object ID for admin access.')
param azureADAdminObjectId string = ''

@description('Resource group name following ThorLabs convention.')
param resourceGroupName string = 'thorlabs-rg'

@description('Deploy enhanced lab infrastructure (VMs, networking, monitoring).')
param deployEnhancedLab bool = true

@description('Deploy container services (ACR, ACI, Container Apps).')
param deployContainerServices bool = false

@description('Deploy database services (SQL, PostgreSQL, Cosmos).')
param deployDatabaseServices bool = false

@description('VM size for Ubuntu server (lab-optimized).')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2'])
param ubuntuVmSize string = 'Standard_B1s'

@description('VM size for Windows server (lab-optimized).')
@allowed(['Standard_B1s', 'Standard_B2s', 'Standard_DS1_v2'])
param windowsVmSize string = 'Standard_B1s'

@description('Enable Sentinel security monitoring.')
param enableSentinel bool = false

@description('Deployment timestamp for resource tagging.')
param deploymentTimestamp string = utcNow('yyyy-MM-dd')

// Common variables
var commonTags = {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
  CreatedBy: 'IaC-Bicep'
  LastModified: deploymentTimestamp
  MasterDeployment: 'true'
}

// === RESOURCE GROUP ===
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// === ENHANCED LAB INFRASTRUCTURE ===
module enhancedLab 'enhanced-lab.bicep' = if (deployEnhancedLab) {
  name: 'enhanced-lab-deployment'
  scope: resourceGroup
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    sshPublicKey: sshPublicKey
    ubuntuVmSize: ubuntuVmSize
    windowsVmSize: windowsVmSize
    enableMonitoring: true
    enableStorage: true
    enableKeyVault: true
    enableSentinel: enableSentinel
    deploymentTimestamp: deploymentTimestamp
  }
}

// === CONTAINER SERVICES ===
module containerServices 'container-services.bicep' = if (deployContainerServices) {
  name: 'container-services-deployment'
  scope: resourceGroup
  dependsOn: [
    enhancedLab
  ]
  params: {
    location: location
    enableContainerRegistry: true
    enableContainerInstances: true
    enableContainerApps: true
    vnetId: deployEnhancedLab ? enhancedLab.outputs.virtualNetworkName : ''
    subnetId: deployEnhancedLab ? resourceId(resourceGroup.name, 'Microsoft.Network/virtualNetworks/subnets', enhancedLab.outputs.virtualNetworkName, 'services-subnet') : ''
    deploymentTimestamp: deploymentTimestamp
  }
}

// === DATABASE SERVICES ===
module databaseServices 'database-services.bicep' = if (deployDatabaseServices) {
  name: 'database-services-deployment'
  scope: resourceGroup
  dependsOn: [
    enhancedLab
  ]
  params: {
    location: location
    dbAdminUsername: adminUsername
    dbAdminPassword: adminPassword
    enableAzureADAuth: enableAzureADAuth
    azureADAdminUpn: azureADAdminUpn
    azureADAdminObjectId: azureADAdminObjectId
    enableSqlDatabase: true
    enablePostgreSQL: true
    enableCosmosDB: true
    vnetId: deployEnhancedLab ? enhancedLab.outputs.virtualNetworkName : ''
    subnetId: deployEnhancedLab ? resourceId(resourceGroup.name, 'Microsoft.Network/virtualNetworks/subnets', enhancedLab.outputs.virtualNetworkName, 'services-subnet') : ''
    deploymentTimestamp: deploymentTimestamp
  }
}

// === OUTPUTS ===
output deploymentSummary object = {
  resourceGroupName: resourceGroup.name
  location: location
  deployedServices: {
    enhancedLab: deployEnhancedLab
    containerServices: deployContainerServices
    databaseServices: deployDatabaseServices
  }
  coreInfrastructure: deployEnhancedLab ? {
    ubuntuVM: {
      name: enhancedLab.outputs.ubuntuVmName
      publicIP: enhancedLab.outputs.ubuntuPublicIP
      sshCommand: enhancedLab.outputs.sshCommand
    }
    windowsVM: {
      name: enhancedLab.outputs.windowsVmName
      publicIP: enhancedLab.outputs.windowsPublicIP
      rdpCommand: enhancedLab.outputs.rdpCommand
    }
    virtualNetwork: enhancedLab.outputs.virtualNetworkName
    storageAccount: enhancedLab.outputs.storageAccountName
    keyVault: enhancedLab.outputs.keyVaultName
    logAnalytics: enhancedLab.outputs.logAnalyticsWorkspaceName
  } : {}
  containerServices: deployContainerServices ? {
    containerRegistry: containerServices.outputs.containerRegistryName
    containerRegistryLoginServer: containerServices.outputs.containerRegistryLoginServer
    containerAppsEnvironment: containerServices.outputs.containerAppsEnvironmentName
    sampleAppUrl: containerServices.outputs.sampleContainerAppUrl
    containerInstanceFqdn: containerServices.outputs.containerInstanceFqdn
  } : {}
  databaseServices: deployDatabaseServices ? {
    sqlServer: databaseServices.outputs.sqlServerName
    sqlDatabase: databaseServices.outputs.sqlDatabaseName
    postgresqlServer: databaseServices.outputs.postgresqlServerName
    cosmosAccount: databaseServices.outputs.cosmosAccountName
    sqlConnectionString: databaseServices.outputs.sqlConnectionString
    postgresqlConnectionString: databaseServices.outputs.postgresqlConnectionString
  } : {}
}

output quickAccessCommands object = deployEnhancedLab ? {
  sshToUbuntu: enhancedLab.outputs.sshCommand
  rdpToWindows: enhancedLab.outputs.rdpCommand
  azLoginCommand: 'az login && az account set --subscription ${subscription().subscriptionId}'
  resourceGroupCommand: 'az group show --name ${resourceGroup.name}'
} : {}

output costOptimizationInfo object = {
  autoShutdownEnabled: true
  autoShutdownTime: '19:00 Eastern Time'
  estimatedMonthlyCost: 'Approximately $50-100 USD with auto-shutdown'
  costSavingTips: [
    'VMs automatically shut down at 7 PM ET daily'
    'Use Basic SKUs for lab workloads'
    'Storage is optimized for lab use with LRS replication'
    'Monitor usage in Azure Cost Management'
  ]
}
