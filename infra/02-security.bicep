// ============================================================================
// ThorLabs Security Services (Layer 2)  
// ============================================================================
// Purpose: Security monitoring and compliance services
// Deployment: Depends on Foundation layer
// Dependencies: Resource Group, Log Analytics Workspace

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Primary deployment region')
param location string = resourceGroup().location

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Environment designation for resource naming')
@allowed(['lab', 'dev', 'staging', 'prod'])
param environment string = 'lab'

@description('Project prefix for consistent naming')
param projectPrefix string = 'thorlabs'

@description('Tags applied to all resources')
param tags object = {
  Project: 'ThorLabs'
  Environment: environment
  Layer: 'Security'
  AutoShutdown_Time: '19:00'
  ManagedBy: 'Bicep'
}

// ============================================================================
// VARIABLES
// ============================================================================

var sentinelSolutionName = 'SecurityInsights(${logAnalyticsWorkspaceName})'

// ============================================================================
// MICROSOFT SENTINEL
// ============================================================================

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: sentinelSolutionName
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspaceId
  }
  plan: {
    name: sentinelSolutionName
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

// ============================================================================
// MICROSOFT DEFENDER INTEGRATION
// ============================================================================

// Microsoft Defender for Cloud Data Connector
resource defenderCloudConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-defender-cloud-${environment}'
  kind: 'MicrosoftDefenderAdvancedThreatProtection'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
  }
}

// Microsoft Defender for Endpoint Connector  
resource defenderEndpointConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-defender-endpoint-${environment}'
  kind: 'MicrosoftThreatProtection'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      incidents: {
        state: 'Enabled'
      }
    }
  }
}

// Microsoft 365 Defender XDR Connector (Unified Portal Integration)
resource m365DefenderConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-m365defender-xdr-${environment}'
  kind: 'MicrosoftThreatIntelligence'
  properties: {
    tenantId: tenant().tenantId
    dataTypes: {
      bingSafetyPhishingURL: {
        state: 'Enabled'
        lookbackPeriod: 'All'
      }
      microsoftEmergingThreatFeed: {
        state: 'Enabled' 
        lookbackPeriod: 'All'
      }
    }
  }
}

// Unified Security Operations Workspace Setting
resource unifiedSecuritySettings 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

// Azure Activity Logs Connector
resource activityLogsConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-activity-logs-${environment}'
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

// Security Events Connector
resource securityEventsConnector 'Microsoft.SecurityInsights/dataConnectors@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-security-events-${environment}'
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

// ============================================================================
// ANALYTICS RULES FOR THORLABS ENVIRONMENT
// ============================================================================

// High Severity Defender Alerts Rule
resource defenderHighSeverityRule 'Microsoft.SecurityInsights/alertRules@2023-02-01' = {
  scope: resourceGroup()
  name: '${projectPrefix}-defender-high-severity-${environment}'
  kind: 'Scheduled'
  properties: {
    displayName: 'ThorLabs - High Severity Defender Alerts'
    description: 'Monitors high-severity alerts from Microsoft Defender for Cloud in ThorLabs environment'
    severity: 'High'
    enabled: true
    query: '''
SecurityAlert
| where TimeGenerated > ago(1h)
| where ProductName contains "Microsoft Defender"
| where AlertSeverity == "High"
| where SystemAlertId contains "thorlabs" or Description contains "thorlabs"
| project TimeGenerated, AlertName, AlertSeverity, Description, CompromisedEntity
'''
    queryFrequency: 'PT1H'
    queryPeriod: 'PT1H'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionDuration: 'PT1H'
    suppressionEnabled: false
    tactics: [
      'DefenseEvasion'
      'Persistence'
      'PrivilegeEscalation'
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

// ============================================================================
// OUTPUTS
// ============================================================================

output sentinelWorkspaceId string = logAnalyticsWorkspaceId
output sentinelSolutionId string = sentinelSolution.id
output defenderCloudConnectorId string = defenderCloudConnector.id
output defenderEndpointConnectorId string = defenderEndpointConnector.id
output m365DefenderConnectorId string = m365DefenderConnector.id
output unifiedSecuritySettingsId string = unifiedSecuritySettings.id
output sentinelPortalUrl string = 'https://portal.azure.com/#@${tenant().tenantId}/blade/Microsoft_Azure_Security_Insights/MainMenuBlade/0/subscriptionId/${subscription().subscriptionId}/resourceGroup/${resourceGroup().name}/workspaceName/${logAnalyticsWorkspaceName}'
output unifiedDefenderPortalUrl string = 'https://security.microsoft.com'
