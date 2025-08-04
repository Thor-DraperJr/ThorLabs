# ThorLabs Development Guide

Comprehensive development patterns and workflows for the ThorLabs Azure lab environment.

## When to Use This Guide

Attach this file when you need:
- **Complex multi-step deployments**
- **Detailed Bicep template patterns**
- **Complete workflow examples**
- **Troubleshooting guidance**

For specific patterns, use the specialized context files:
- `bicep-patterns.md` - Template examples
- `azure-mcp-reference.md` - MCP server tools
- `security-standards.md` - Security configurations

## Development Workflow

### 1. Pre-Development (Always Required)
```yaml
1. Call mcp_azure_mcp_ser_bestpractices
2. Call mcp_azure_mcp_ser_bicepschema (for infrastructure)
3. Review security-standards.md for compliance
4. Follow thorlabs-{service}{number}-{region} naming
```

### 2. Infrastructure Development
```bicep
// Standard template structure
param location string = resourceGroup().location
param resourceName string = 'thorlabs-vm1-eastus2'

@allowed(['Standard_B1s', 'Standard_B2s'])
param vmSize string = 'Standard_B1s'

// Required tags
var commonTags = {
  Environment: 'Lab'
  Project: 'ThorLabs'
  AutoShutdown_Time: '19:00'
  AutoShutdown_TimeZone: 'Eastern Standard Time'
}
```

### 3. Deployment Process
```yaml
# Using Azure MCP server
1. Use mcp_azure_mcp_ser_extension_azd for full environments
2. Use mcp_azure_mcp_ser_extension_az for individual resources
3. Validate with bicep build before deployment
4. Test in isolated resource group first
```

## Quality Gates

### Before Pull Request
- [ ] Azure MCP server tools used for all Azure operations
- [ ] Naming convention followed: `thorlabs-{service}{number}-{region}`
- [ ] Required tags applied to all resources
- [ ] Security standards from security-standards.md applied
- [ ] Documentation updated in README.md
- [ ] Bicep templates validated

### Deployment Checklist
- [ ] Resource group exists: `thorlabs-rg`
- [ ] Parameters file configured correctly
- [ ] Azure CLI authenticated to correct subscription
- [ ] Deployment command uses verbose output
- [ ] Post-deployment validation completed

## Common Patterns

### Resource Group Creation
```bash
az group create --name thorlabs-rg --location eastus2
```

### Bicep Deployment
```bash
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file infra/template.bicep \
  --parameters @infra/template.parameters.json \
  --verbose
```

### Azure Developer CLI
```bash
azd init
azd up --environment lab
```

## Troubleshooting

### Common Issues
1. **Naming conflicts**: Check existing resources in subscription
2. **Permission errors**: Verify RBAC assignments
3. **Template validation**: Use `bicep build` locally
4. **MCP server errors**: Retry with `learn=true` parameter

### Debug Commands
```bash
# Check current subscription
az account show

# List resource groups
az group list --output table

# Validate template
az deployment group validate \
  --resource-group thorlabs-rg \
  --template-file template.bicep
```

This guide complements the specialized context files and provides comprehensive workflow guidance for complex development tasks.
