# ThorLabs Security Standards

Security patterns and standards for Azure resources in the ThorLabs lab environment.

## Core Security Principles

### 1. Authentication & Authorization
- **Managed Identity**: Preferred for Azure-hosted resources
- **Service Principal**: For CI/CD pipelines only
- **Key Vault**: For all secrets and certificates
- **RBAC**: Principle of least privilege

### 2. Network Security
- **NSG Rules**: Explicit allow rules only
- **HTTPS Only**: All traffic encrypted in transit
- **Private Endpoints**: For production workloads
- **IP Restrictions**: Limit access to known IP ranges

### 3. Data Protection
- **Encryption at Rest**: Always enabled
- **TLS 1.2+**: Minimum encryption standard
- **Key Management**: Azure-managed keys preferred
- **Backup**: Enabled with appropriate retention

## Required Security Configurations

### Storage Accounts
```bicep
properties: {
  allowBlobPublicAccess: false
  allowSharedKeyAccess: true  // Lab only - use false in production
  minimumTlsVersion: 'TLS1_2'
  supportsHttpsTrafficOnly: true
  encryption: {
    services: {
      blob: { enabled: true }
      file: { enabled: true }
    }
    keySource: 'Microsoft.Storage'
  }
  networkAcls: {
    defaultAction: 'Deny'  // Production - use 'Allow' for lab simplicity
    bypass: 'AzureServices'
  }
}
```

### Virtual Machines
```bicep
properties: {
  osProfile: {
    adminUsername: adminUsername
    adminPassword: adminPassword  // Use Key Vault reference in production
    linuxConfiguration: {
      disablePasswordAuthentication: false  // Use SSH keys in production
    }
  }
  storageProfile: {
    osDisk: {
      createOption: 'FromImage'
      managedDisk: {
        storageAccountType: 'Premium_LRS'  // Better security with SSD
      }
    }
  }
}
```

### Key Vault
```bicep
properties: {
  enabledForDeployment: false
  enabledForDiskEncryption: false
  enabledForTemplateDeployment: true  // Lab use only
  enableSoftDelete: true
  softDeleteRetentionInDays: 7  // Lab - use 90 in production
  enablePurgeProtection: false  // Enable in production
  publicNetworkAccess: 'Enabled'  // Disable in production
  networkAcls: {
    defaultAction: 'Allow'  // Change to 'Deny' in production
    bypass: 'AzureServices'
  }
}
```

## Network Security Group Patterns

### SSH Access (Linux VMs)
```bicep
{
  name: 'SSH-Access'
  properties: {
    priority: 1000
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '0.0.0.0/0'  // Restrict to specific IPs in production
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '22'
    description: 'Allow SSH access - restrict source IPs in production'
  }
}
```

### RDP Access (Windows VMs)
```bicep
{
  name: 'RDP-Access'
  properties: {
    priority: 1001
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '0.0.0.0/0'  // Restrict to specific IPs in production
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '3389'
    description: 'Allow RDP access - restrict source IPs in production'
  }
}
```

### HTTPS Only (Web Applications)
```bicep
{
  name: 'HTTPS-Access'
  properties: {
    priority: 1002
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '443'
    description: 'Allow HTTPS traffic only'
  }
}
```

## Identity and Access Management

### Managed Identity Assignment
```bicep
identity: {
  type: 'SystemAssigned'
}
```

### Role Assignment Pattern
```bicep
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
```

## Common Role Definition IDs

| Role | ID | Use Case |
|------|----|---------| 
| Storage Blob Data Reader | `2a2b9908-6ea1-4ae2-8e65-a410df84e7d1` | Read blob data |
| Storage Blob Data Contributor | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` | Read/write blob data |
| Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Read secrets |
| Virtual Machine Contributor | `9980e02c-c2be-4d73-94e8-173b1dc7cf3c` | Manage VMs |

## Compliance Requirements

### Required Tags
```bicep
tags: {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
  DataClassification: 'Internal'  // Add for production
  Owner: 'team@thorlabs.com'      // Add for production
}
```

### Monitoring and Logging
- **Diagnostic Settings**: Enable for all resources
- **Activity Logs**: Retain for minimum 90 days
- **Security Center**: Enable standard tier
- **Azure Sentinel**: For advanced threat detection

## Lab vs Production Differences

| Setting | Lab Value | Production Value |
|---------|-----------|------------------|
| Public Access | Allowed | Restricted/Denied |
| Shared Key Access | Enabled | Disabled |
| Soft Delete Retention | 7 days | 90 days |
| Purge Protection | Disabled | Enabled |
| Network Access | Allow | Deny (with exceptions) |
| SSH/RDP Source | 0.0.0.0/0 | Specific IP ranges |

## Security Checklist

- [ ] All resources have required tags
- [ ] Encryption enabled for data at rest
- [ ] HTTPS-only traffic enforced
- [ ] Network access properly restricted
- [ ] Managed identities used where possible
- [ ] Secrets stored in Key Vault
- [ ] Diagnostic logging enabled
- [ ] Role assignments follow least privilege
- [ ] Public access disabled for storage
- [ ] Strong passwords or SSH keys used
