# ThorLabs Azure Lab Environment: Copilot Instructions

## ALWAYS: Use Azure MCP Server Tools First
When working with Azure, **ALWAYS** use these MCP server tools:
- `mcp_azure_mcp_ser_bestpractices` → Before generating any Azure code
- `mcp_azure_mcp_ser_bicepschema` → Before creating Bicep resources  
- `mcp_azure_mcp_ser_extension_az` → For Azure CLI operations
- `mcp_azure_mcp_ser_extension_azd` → For Azure Developer CLI

## ALWAYS: Follow ThorLabs Patterns
- **Naming**: `thorlabs-{service}{number}-{region}` (e.g., `thorlabs-st1-eastus2`)
- **Tags**: Include `Environment: 'Lab'`, `Project: 'ThorLabs'`, `AutoShutdown_Time: '19:00'`
- **IaC**: Bicep templates only (never Terraform/ARM)
- **Security**: Managed Identity preferred, never hardcode secrets

## CONTEXT: Creating Bicep Templates
1. Call `mcp_azure_mcp_ser_bestpractices` first
2. Call `mcp_azure_mcp_ser_bicepschema` for resource schemas
3. Follow ThorLabs naming and tagging patterns
4. Include parameter validation with `@allowed` decorators

## CONTEXT: Azure CLI Operations  
1. Use `mcp_azure_mcp_ser_extension_az` for all CLI commands
2. Follow ThorLabs naming conventions
3. Include proper error handling

## PROHIBITED
❌ Terraform/ARM templates ❌ Hardcoded secrets ❌ Generic Ubuntu ❌ Bypassing MCP server

## CONTEXT FILES
For detailed patterns, attach from `.github/context/`:
- `bicep-patterns.md` - Template examples and schemas
- `azure-mcp-reference.md` - MCP server tool usage
- `security-standards.md` - Security configurations
- `development-guide.md` - Complete development workflows
