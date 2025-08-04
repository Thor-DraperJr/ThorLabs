// container-services.bicep - Container workloads for ThorLabs Lab
// Azure Container Registry, Container Instances, and Container Apps
// Following Azure MCP best practices and ThorLabs conventions

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('Enable Azure Container Registry.')
param enableContainerRegistry bool = true

@description('Enable Azure Container Instances.')
param enableContainerInstances bool = false

@description('Enable Azure Container Apps.')
param enableContainerApps bool = false

@description('Virtual network resource ID for integration.')
param vnetId string

@description('Subnet resource ID for container services.')
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

// === AZURE CONTAINER REGISTRY ===
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-04-01-preview' = if (enableContainerRegistry) {
  name: '${projectName}acr1${regionCode}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
  tags: commonTags
}

// === AZURE CONTAINER APPS ENVIRONMENT ===
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = if (enableContainerApps) {
  name: '${projectName}-cae1-${regionCode}'
  location: location
  properties: {
    zoneRedundant: false
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: subnetId
    }
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
  }
  tags: commonTags
}

// Sample Container App for testing
resource sampleContainerApp 'Microsoft.App/containerApps@2024-03-01' = if (enableContainerApps) {
  name: '${projectName}-app1-${regionCode}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
        allowInsecure: false
      }
      registries: enableContainerRegistry ? [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ] : []
      secrets: enableContainerRegistry ? [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: 'simple-hello-world-container'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ENVIRONMENT'
              value: 'Lab'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scale'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
  tags: commonTags
}

// === AZURE CONTAINER INSTANCES ===
resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2024-10-01-preview' = if (enableContainerInstances) {
  name: '${projectName}-aci1-${regionCode}'
  location: location
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: 'nginx-container'
        properties: {
          image: 'nginx:latest'
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: json('1.5')
            }
          }
          environmentVariables: [
            {
              name: 'ENVIRONMENT'
              value: 'Lab'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    }
  }
  tags: commonTags
}

// === OUTPUTS ===
output containerRegistryName string = enableContainerRegistry ? containerRegistry.name : ''
output containerRegistryLoginServer string = enableContainerRegistry ? containerRegistry.properties.loginServer : ''
output containerAppsEnvironmentName string = enableContainerApps ? containerAppsEnvironment.name : ''
output sampleContainerAppUrl string = enableContainerApps ? 'https://${sampleContainerApp.properties.configuration.ingress.fqdn}' : ''
output containerInstanceFqdn string = enableContainerInstances ? containerInstance.properties.ipAddress.fqdn : ''
output containerInstanceIp string = enableContainerInstances ? containerInstance.properties.ipAddress.ip : ''
