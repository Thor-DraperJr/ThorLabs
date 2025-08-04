// database-services.bicep - Database services for ThorLabs Lab
// Azure SQL Database, PostgreSQL, and CosmosDB for comprehensive database testing
// Following Azure MCP best practices and ThorLabs conventions

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Administrator username for database servers (only used if Azure AD auth is disabled).')
@minLength(3)
@maxLength(20)
param dbAdminUsername string = 'thorlabsadmin'

@description('Administrator password for database servers (only used if Azure AD auth is disabled).')
@secure()
@minLength(12)
@maxLength(128)
param dbAdminPassword string = 'TempPassword123!'

@description('Enable Azure AD authentication (recommended). When enabled, you can use your Azure identity.')
param enableAzureADAuth bool = true

@description('Your Azure AD user principal name (email) to be set as admin.')
param azureADAdminUpn string = ''

@description('Your Azure AD user object ID to be set as admin.')
param azureADAdminObjectId string = ''

@description('Enable Azure SQL Database.')
param enableSqlDatabase bool = true

@description('Enable Azure Database for PostgreSQL.')
param enablePostgreSQL bool = false

@description('Enable Azure Cosmos DB.')
param enableCosmosDB bool = false

@description('Virtual network resource ID for integration.')
param vnetId string

@description('Subnet resource ID for database services.')
param subnetId string

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

// === AZURE SQL DATABASE ===
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = if (enableSqlDatabase) {
  name: '${projectName}-sql1-${regionCode}'
  location: location
  properties: {
    administratorLogin: enableAzureADAuth ? null : dbAdminUsername
    administratorLoginPassword: enableAzureADAuth ? null : dbAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
  tags: commonTags
}

// Azure AD Admin for SQL Server
resource sqlServerAzureADAdmin 'Microsoft.Sql/servers/administrators@2024-05-01-preview' = if (enableSqlDatabase && enableAzureADAuth && azureADAdminObjectId != '') {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: azureADAdminUpn
    sid: azureADAdminObjectId
    tenantId: subscription().tenantId
  }
}

resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = if (enableSqlDatabase) {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = if (enableSqlDatabase) {
  parent: sqlServer
  name: '${projectName}-db1-${regionCode}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824 // 1GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
  tags: commonTags
}

// === AZURE DATABASE FOR POSTGRESQL ===
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = if (enablePostgreSQL) {
  name: '${projectName}-pg1-${regionCode}'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '15'
    administratorLogin: enableAzureADAuth ? null : dbAdminUsername
    administratorLoginPassword: enableAzureADAuth ? null : dbAdminPassword
    authConfig: enableAzureADAuth ? {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    } : {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
    storage: {
      storageSizeGB: 32
      tier: 'P4'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
  tags: commonTags
}

// Azure AD Admin for PostgreSQL
resource postgresqlAzureADAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = if (enablePostgreSQL && enableAzureADAuth && azureADAdminObjectId != '') {
  parent: postgresqlServer
  name: azureADAdminObjectId
  properties: {
    principalType: 'User'
    principalName: azureADAdminUpn
    tenantId: subscription().tenantId
  }
}

resource postgresqlFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = if (enablePostgreSQL) {
  parent: postgresqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource postgresqlDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = if (enablePostgreSQL) {
  parent: postgresqlServer
  name: '${projectName}testdb'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// === AZURE COSMOS DB ===
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' = if (enableCosmosDB) {
  name: '${projectName}-cosmos1-${regionCode}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    enableFreeTier: true
    enableAnalyticalStorage: false
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Enabled'
    disableKeyBasedMetadataWriteAccess: false
    networkAclBypass: 'AzureServices'
  }
  tags: commonTags
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-12-01-preview' = if (enableCosmosDB) {
  parent: cosmosAccount
  name: '${projectName}TestDB'
  properties: {
    resource: {
      id: '${projectName}TestDB'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = if (enableCosmosDB) {
  parent: cosmosDatabase
  name: 'TestContainer'
  properties: {
    resource: {
      id: 'TestContainer'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

// === OUTPUTS ===
output sqlServerName string = enableSqlDatabase ? sqlServer.name : ''
output sqlDatabaseName string = enableSqlDatabase ? sqlDatabase.name : ''
output sqlServerFqdn string = enableSqlDatabase ? sqlServer.properties.fullyQualifiedDomainName : ''
output postgresqlServerName string = enablePostgreSQL ? postgresqlServer.name : ''
output postgresqlServerFqdn string = enablePostgreSQL ? postgresqlServer.properties.fullyQualifiedDomainName : ''
output cosmosAccountName string = enableCosmosDB ? cosmosAccount.name : ''
output cosmosAccountEndpoint string = enableCosmosDB ? cosmosAccount.properties.documentEndpoint : ''

// Connection strings for Azure AD authentication
output sqlConnectionStringAzureAD string = enableSqlDatabase && enableAzureADAuth ? 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabase.name};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' : ''
output postgresqlConnectionStringAzureAD string = enablePostgreSQL && enableAzureADAuth ? 'Host=${postgresqlServer.properties.fullyQualifiedDomainName};Database=${postgresqlDatabase.name};SSL Mode=Require;' : ''

// Legacy connection strings for SQL authentication (when Azure AD is disabled)
output sqlConnectionString string = enableSqlDatabase && !enableAzureADAuth ? 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabase.name};User ID=${dbAdminUsername};Password=***;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' : ''
output postgresqlConnectionString string = enablePostgreSQL && !enableAzureADAuth ? 'Host=${postgresqlServer.properties.fullyQualifiedDomainName};Database=${postgresqlDatabase.name};Username=${dbAdminUsername};Password=***;SSL Mode=Require;' : ''

// Authentication method information
output authenticationMethod string = enableAzureADAuth ? 'Azure AD (Passwordless)' : 'SQL Authentication'
output azureADAdminConfigured string = enableAzureADAuth && azureADAdminObjectId != '' ? 'Yes' : 'No'
