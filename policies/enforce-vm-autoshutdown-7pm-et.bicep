// enforce-vm-autoshutdown-7pm-et.bicep
// Defines and assigns an Azure Policy to audit VMs for auto-shutdown tags at subscription scope

targetScope = 'subscription'

@description('Required shutdown time in 24-hour format (default: 19:00 for 7 PM)')
param requiredShutdownTime string = '19:00'

@description('Required time zone (default: Eastern Standard Time)')
param requiredTimeZone string = 'Eastern Standard Time'

@description('The assignment name for the policy')
param assignmentName string = 'audit-vm-autoshutdown-assignment'

@description('The display name for the policy assignment')
param assignmentDisplayName string = 'Audit VM Auto-Shutdown Tags (7 PM ET)'

@description('The description for the policy assignment')
param assignmentDescription string = 'Audits VMs to ensure they have required auto-shutdown tags for cost control'

var policyDefinitionName = 'audit-vm-autoshutdown-7pm-et'
var policyDefinitionDisplayName = 'Audit VMs for Auto-Shutdown Tags (7 PM ET)'
var policyDefinitionDescription = 'This policy audits virtual machines to ensure they have the required auto-shutdown tags: AutoShutdown_Time set to specified time and AutoShutdown_TimeZone set to specified timezone. VMs without these tags will be flagged as non-compliant.'

// Define the policy definition
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyDefinitionName
  properties: {
    displayName: policyDefinitionDisplayName
    description: policyDefinitionDescription
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Compute'
      version: '1.0.0'
    }
    parameters: {
      requiredShutdownTime: {
        type: 'String'
        defaultValue: requiredShutdownTime
        metadata: {
          displayName: 'Required Shutdown Time'
          description: 'The required value for the AutoShutdown_Time tag (24-hour format)'
        }
      }
      requiredTimeZone: {
        type: 'String'
        defaultValue: requiredTimeZone
        metadata: {
          displayName: 'Required Time Zone'
          description: 'The required value for the AutoShutdown_TimeZone tag'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            anyOf: [
              {
                field: 'tags[\'AutoShutdown_Time\']'
                notEquals: '[parameters(\'requiredShutdownTime\')]'
              }
              {
                field: 'tags[\'AutoShutdown_TimeZone\']'
                notEquals: '[parameters(\'requiredTimeZone\')]'
              }
              {
                field: 'tags[\'AutoShutdown_Time\']'
                exists: 'false'
              }
              {
                field: 'tags[\'AutoShutdown_TimeZone\']'
                exists: 'false'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'audit'
      }
    }
  }
}

// Assign the policy to the subscription
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  properties: {
    displayName: assignmentDisplayName
    description: assignmentDescription
    policyDefinitionId: policyDefinition.id
    parameters: {
      requiredShutdownTime: {
        value: requiredShutdownTime
      }
      requiredTimeZone: {
        value: requiredTimeZone
      }
    }
    enforcementMode: 'Default'
  }
}

// Outputs
output policyDefinitionId string = policyDefinition.id
output policyAssignmentId string = policyAssignment.id
output policyDefinitionName string = policyDefinitionName
output assignmentName string = assignmentName