// thorlabs-sentinel.bicep - ThorLabs Azure Sentinel Security Operations Center
// Deploys Azure Sentinel with Log Analytics workspace for security monitoring and threat detection
// Updated for Azure MCP compliance with latest API versions and security best practices

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Log Analytics workspace name following ThorLabs naming convention.')
@minLength(4)
@maxLength(63)
param workspaceName string = 'thorlabs-sentinel1-eastus2'

@description('Workspace data retention in days (90-730 days for Sentinel).')
@minValue(90)
@maxValue(730)
param retentionInDays int = 90

@description('Daily ingestion limit in GB. Set to -1 for unlimited.')
@minValue(-1)
param dailyQuotaGb int = 5

@description('Workspace SKU pricing tier.')
@allowed(['Free', 'Standard', 'Premium', 'PerNode', 'PerGB2018', 'Standalone', 'CapacityReservation'])
param skuName string = 'PerGB2018'

@description('Enable public network access for data ingestion.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Enable public network access for query.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccessForQuery string = 'Enabled'

@description('Use existing Log Analytics workspace instead of creating new one.')
param useExistingWorkspace bool = true

@description('Existing workspace resource group (if different from current deployment).')
param existingWorkspaceResourceGroup string = resourceGroup().name

@description('Enable Sentinel data connectors for common Microsoft services.')
param enableDataConnectors bool = true

// Reference existing Log Analytics Workspace (if useExistingWorkspace is true)
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = if (useExistingWorkspace) {
  name: workspaceName
  scope: resourceGroup(existingWorkspaceResourceGroup)
}

// Create new Log Analytics Workspace for Sentinel (only if useExistingWorkspace is false)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = if (!useExistingWorkspace) {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
      enableDataExport: false
      immediatePurgeDataOn30Days: false
    }
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    Purpose: 'Security Operations Center'
    Service: 'Sentinel'
  }
}

// Get the correct workspace reference
var workspaceReference = useExistingWorkspace ? existingLogAnalyticsWorkspace : logAnalyticsWorkspace

// Security Insights (Sentinel) Solution
resource securityInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceReference.id
    containedResources: []
  }
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    Purpose: 'Security Operations Center'
    Service: 'Sentinel'
  }
}

// Sentinel Onboarding State for existing workspace
resource sentinelOnboardingStateExisting 'Microsoft.SecurityInsights/onboardingStates@2023-02-01' = if (useExistingWorkspace) {
  name: '${existingLogAnalyticsWorkspace.name}/default'
  properties: {
    customerManagedKey: false
  }
}

// Sentinel Onboarding State for new workspace  
resource sentinelOnboardingStateNew 'Microsoft.SecurityInsights/onboardingStates@2023-02-01' = if (!useExistingWorkspace) {
  name: '${logAnalyticsWorkspace.name}/default'
  properties: {
    customerManagedKey: false
  }
}

// Azure Activity Data Connector (if enabled)
resource azureActivityDataConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = if (enableDataConnectors) {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-activity-connector'
  kind: 'AzureActivityLogs'
  properties: {
    subscriptionId: subscription().subscriptionId
    dataTypes: {
      logs: {
        state: 'Enabled'
      }
    }
  }
}

// Security Events Data Connector (if enabled)
resource securityEventsDataConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = if (enableDataConnectors) {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-security-events-connector'
  kind: 'SecurityEvents'
  properties: {
    dataTypes: {
      securityEvents: {
        state: 'Enabled'
        filters: {
          operation: 'Equal'
          value: 'Recommended'
        }
      }
    }
  }
}

// Office 365 Data Connector (if enabled)
resource office365DataConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = if (enableDataConnectors) {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-office365-connector'
  kind: 'Office365'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      exchange: {
        state: 'Enabled'
      }
      sharePoint: {
        state: 'Enabled'
      }
      teams: {
        state: 'Enabled'
      }
    }
  }
}

// Azure AD Data Connector (if enabled)
resource azureADDataConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = if (enableDataConnectors) {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-azuread-connector'
  kind: 'AzureActiveDirectory'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
  }
}

// Basic Analytics Rules for ThorLabs Environment
resource suspiciousLoginRule 'Microsoft.SecurityInsights/alertRules@2023-02-01' = {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-suspicious-login-rule'
  kind: 'Scheduled'
  properties: {
    displayName: 'ThorLabs - Suspicious Login Activity'
    description: 'Detects suspicious login activity in the ThorLabs environment'
    severity: 'Medium'
    enabled: true
    query: '''
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != 0
| where UserPrincipalName contains "thorlabs" or AppDisplayName contains "ThorLabs"
| summarize FailedAttempts = count() by UserPrincipalName, IPAddress, bin(TimeGenerated, 5m)
| where FailedAttempts >= 5
'''
    queryFrequency: 'PT1H'
    queryPeriod: 'PT1H'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionDuration: 'PT1H'
    suppressionEnabled: false
    tactics: [
      'CredentialAccess'
      'InitialAccess'
    ]
    techniques: [
      'T1110'
      'T1078'
    ]
    entityMappings: [
      {
        entityType: 'Account'
        fieldMappings: [
          {
            identifier: 'FullName'
            columnName: 'UserPrincipalName'
          }
        ]
      }
      {
        entityType: 'IP'
        fieldMappings: [
          {
            identifier: 'Address'
            columnName: 'IPAddress'
          }
        ]
      }
    ]
    alertDetailsOverride: {
      alertDisplayNameFormat: 'Suspicious login activity detected for {{UserPrincipalName}}'
      alertDescriptionFormat: '{{FailedAttempts}} failed login attempts detected from IP {{IPAddress}}'
    }
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: true
        reopenClosedIncident: false
        lookbackDuration: 'PT1H'
        matchingMethod: 'AllEntities'
      }
    }
  }
}

resource vmSecurityRule 'Microsoft.SecurityInsights/alertRules@2023-02-01' = {
  scope: logAnalyticsWorkspace
  name: 'thorlabs-vm-security-rule'
  kind: 'Scheduled'
  properties: {
    displayName: 'ThorLabs - VM Security Events'
    description: 'Monitors security events on ThorLabs virtual machines'
    severity: 'High'
    enabled: true
    query: '''
SecurityEvent
| where TimeGenerated > ago(1h)
| where Computer contains "thorlabs"
| where EventID in (4625, 4648, 4719, 4720, 4722, 4724, 4728, 4732, 4756)
| summarize EventCount = count() by Computer, Account, EventID, bin(TimeGenerated, 10m)
| where EventCount >= 3
'''
    queryFrequency: 'PT1H'
    queryPeriod: 'PT1H'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionDuration: 'PT1H'
    suppressionEnabled: false
    tactics: [
      'PrivilegeEscalation'
      'Persistence'
      'CredentialAccess'
    ]
    techniques: [
      'T1078'
      'T1136'
      'T1484'
    ]
    entityMappings: [
      {
        entityType: 'Host'
        fieldMappings: [
          {
            identifier: 'HostName'
            columnName: 'Computer'
          }
        ]
      }
      {
        entityType: 'Account'
        fieldMappings: [
          {
            identifier: 'Name'
            columnName: 'Account'
          }
        ]
      }
    ]
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: true
        reopenClosedIncident: false
        lookbackDuration: 'PT2H'
        matchingMethod: 'AllEntities'
      }
    }
  }
}

// Workbook for ThorLabs Security Overview (existing workspace)
resource thorlabsWorkbookExisting 'Microsoft.SecurityInsights/workbooks@2023-02-01' = if (useExistingWorkspace) {
  name: guid('thorlabs-security-overview-existing', existingLogAnalyticsWorkspace.id)
  properties: {
    displayName: 'ThorLabs Security Overview'
    description: 'Security monitoring dashboard for ThorLabs environment'
    category: 'sentinel'
    sourceId: existingLogAnalyticsWorkspace.id
    serializedData: '''{
      "version": "Notebook/1.0",
      "items": [
        {
          "type": 1,
          "content": {
            "json": "# ThorLabs Security Operations Center\\n\\nWelcome to the ThorLabs SOC dashboard. This workbook provides an overview of security events and incidents in your lab environment."
          }
        },
        {
          "type": 3,
          "content": {
            "version": "KqlItem/1.0",
            "query": "SecurityEvent\\n| where TimeGenerated > ago(24h)\\n| where Computer contains \\"thorlabs\\"\\n| summarize EventCount = count() by EventID, Computer\\n| order by EventCount desc\\n| take 10",
            "size": 0,
            "title": "Top Security Events (Last 24h)",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        },
        {
          "type": 3,
          "content": {
            "version": "KqlItem/1.0",
            "query": "SigninLogs\\n| where TimeGenerated > ago(24h)\\n| where UserPrincipalName contains \\"thorlabs\\"\\n| summarize LoginCount = count() by UserPrincipalName, ResultType\\n| order by LoginCount desc",
            "size": 0,
            "title": "Login Activity (Last 24h)",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        }
      ]
    }'''
  }
}

// Workbook for ThorLabs Security Overview (new workspace)
resource thorlabsWorkbookNew 'Microsoft.SecurityInsights/workbooks@2023-02-01' = if (!useExistingWorkspace) {
  name: guid('thorlabs-security-overview-new', logAnalyticsWorkspace.id)
  properties: {
    displayName: 'ThorLabs Security Overview'
    description: 'Security monitoring dashboard for ThorLabs environment'
    category: 'sentinel'
    sourceId: logAnalyticsWorkspace.id
    serializedData: '''{
      "version": "Notebook/1.0",
      "items": [
        {
          "type": 1,
          "content": {
            "json": "# ThorLabs Security Operations Center\\n\\nWelcome to the ThorLabs SOC dashboard. This workbook provides an overview of security events and incidents in your lab environment."
          }
        },
        {
          "type": 3,
          "content": {
            "version": "KqlItem/1.0",
            "query": "SecurityEvent\\n| where TimeGenerated > ago(24h)\\n| summarize EventCount = count() by Computer, EventID\\n| order by EventCount desc\\n| take 10",
            "size": 0,
            "title": "Top Security Events (Last 24h)",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        },
        {
          "type": 3,
          "content": {
            "version": "KqlItem/1.0",
            "query": "SigninLogs\\n| where TimeGenerated > ago(24h)\\n| where UserPrincipalName contains \\"thorlabs\\"\\n| summarize LoginCount = count() by UserPrincipalName, ResultType\\n| order by LoginCount desc",
            "size": 0,
            "title": "Login Activity (Last 24h)",
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        }
      ]
    }'''
  }
}

// Outputs
@description('Log Analytics Workspace Name')
output workspaceName string = useExistingWorkspace ? existingLogAnalyticsWorkspace.name : logAnalyticsWorkspace.name

@description('Log Analytics Workspace Resource ID')
output workspaceResourceId string = useExistingWorkspace ? existingLogAnalyticsWorkspace.id : logAnalyticsWorkspace.id

@description('Log Analytics Workspace Customer ID')
output workspaceCustomerId string = useExistingWorkspace ? existingLogAnalyticsWorkspace.properties.customerId : logAnalyticsWorkspace.properties.customerId

@description('Sentinel Workspace URL')
output sentinelUrl string = 'https://portal.azure.com/#@${tenant().tenantId}/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/${subscription().subscriptionId}/resourceGroup/${resourceGroup().name}/workspaceName/${workspaceName}'

@description('Log Analytics Workspace Location')
output workspaceLocation string = useExistingWorkspace ? existingLogAnalyticsWorkspace.location : logAnalyticsWorkspace.location

@description('Security Insights Solution Name')
output securityInsightsSolutionName string = securityInsights.name
