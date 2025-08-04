# Azure MCP Server Tools Reference

Complete reference for Azure MCP server tools used in ThorLabs development.

## Core MCP Tools (Always Use First)

### `mcp_azure_mcp_ser_bestpractices`
**When**: Before generating any Azure code
**Purpose**: Get secure, production-grade Azure patterns
```yaml
Parameters:
  command: bestpractices_get
  parameters: 
    resource: "general" | "azurefunctions" | "static-web-app"
    action: "code-generation" | "deployment"
```

### `mcp_azure_mcp_ser_bicepschema`
**When**: Before creating Bicep resources
**Purpose**: Get latest resource schemas and API versions
```yaml
Parameters:
  command: get_resource_schema
  parameters:
    resourceType: "Microsoft.Storage/storageAccounts"
```

## Deployment Tools

### `mcp_azure_mcp_ser_extension_azd`
**When**: Deploying complete environments
**Purpose**: Azure Developer CLI operations
```yaml
Parameters:
  command: "up" | "down" | "deploy" | "provision"
  cwd: "/path/to/project"
  environment: "dev" | "test" | "prod"
```

### `mcp_azure_mcp_ser_extension_az`
**When**: Azure CLI operations
**Purpose**: Resource management and queries
```yaml
Parameters:
  command: "group create --name thorlabs-rg --location eastus2"
```

## Resource-Specific Tools

### `mcp_azure_mcp_ser_storage`
**When**: Working with storage accounts
**Purpose**: Storage operations and queries
```yaml
Use for: Blob operations, container management, access policies
```

### `mcp_azure_mcp_ser_keyvault`
**When**: Working with Key Vault
**Purpose**: Secret management operations
```yaml
Use for: Secret retrieval, certificate management, access policies
```

### `mcp_azure_mcp_ser_subscription`
**When**: Working with subscriptions
**Purpose**: Subscription management and queries
```yaml
Use for: Listing subscriptions, quota checks, resource group operations
```

## Workflow Patterns

### Creating New Infrastructure
1. `mcp_azure_mcp_ser_bestpractices` → Get patterns
2. `mcp_azure_mcp_ser_bicepschema` → Get schemas
3. Create Bicep template with patterns
4. `mcp_azure_mcp_ser_extension_azd` → Deploy

### Managing Existing Resources
1. `mcp_azure_mcp_ser_extension_az` → Query current state
2. Resource-specific MCP tool → Detailed operations
3. `mcp_azure_mcp_ser_extension_az` → Apply changes

### Troubleshooting Deployments
1. `mcp_azure_mcp_ser_extension_azd` → Check deployment status
2. `mcp_azure_mcp_ser_extension_az` → Query resource state
3. Resource-specific MCP tool → Detailed diagnostics

## Common MCP Tool Combinations

| Task | Tools to Use | Order |
|------|-------------|-------|
| New VM | `bestpractices` → `bicepschema` → `extension_azd` | 1→2→3 |
| Storage Setup | `bestpractices` → `bicepschema` → `storage` → `extension_az` | 1→2→3→4 |
| Key Vault Config | `bestpractices` → `keyvault` → `extension_az` | 1→2→3 |
| Full Environment | `bestpractices` → `bicepschema` → `extension_azd` | 1→2→3 |

## Error Handling

When MCP tools fail:
1. Check authentication state
2. Verify subscription access
3. Retry with `learn=true` parameter to discover available commands
4. Use alternative tool if primary fails
