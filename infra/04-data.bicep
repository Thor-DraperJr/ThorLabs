// ============================================================================
// ThorLabs Data Services (Layer 4)
// ============================================================================
// Purpose: Database and storage services
// Deployment: Depends on Foundation layer 
// Dependencies: Resource Group, VNet, Key Vault

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

@description('SQL Server admin username')
param sqlAdminUsername string = 'thorlabsadmin'

@description('SQL Server admin password')
@secure()
param sqlAdminPassword string

@description('Enable Azure AD authentication for SQL')
param enableAzureADAuth bool = false

@description('Azure AD admin UPN for SQL Server')
param azureADAdminUpn string = ''

@description('Azure AD admin Object ID for SQL Server')
param azureADAdminObjectId string = ''

@description('Environment designation for resource naming')
@allowed(['lab', 'dev', 'staging', 'prod'])
param environment string = 'lab'

@description('Project prefix for consistent naming')
param projectPrefix string = 'thorlabs'

@description('Tags applied to all resources')
param tags object = {
  Project: 'ThorLabs'
  Environment: environment
  Layer: 'Data'
  AutoShutdown_Time: '19:00'
  ManagedBy: 'Bicep'
}

// ============================================================================
// VARIABLES
// ============================================================================

var sqlServerName = '${projectPrefix}-sql1-${location}'
var sqlDatabaseName = '${projectPrefix}-db1'
var storageAccountName = replace('${projectPrefix}st1${location}', '-', '')

// ============================================================================
// STORAGE ACCOUNT
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// ============================================================================
// SQL SERVER
// ============================================================================

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// ============================================================================
// SQL DATABASE
// ============================================================================

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
  }
}

// ============================================================================
// SQL FIREWALL RULES
// ============================================================================

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ============================================================================
// AZURE AD ADMIN (CONDITIONAL)
// ============================================================================

resource sqlAzureADAdmin 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = if (enableAzureADAuth && !empty(azureADAdminUpn) && !empty(azureADAdminObjectId)) {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: azureADAdminUpn
    sid: azureADAdminObjectId
    tenantId: tenant().tenantId
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output sqlServerName string = sqlServer.name
output sqlServerId string = sqlServer.id
output sqlDatabaseName string = sqlDatabase.name
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
