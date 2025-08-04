# ThorLabs Azure Lab Environment: Copilot Instructions

## ALWAYS: Use Azure MCP Server Tools First
When working with Azure, **ALWAYS** use these MCP server tools:
- `mcp_azure_mcp_ser_bestpractices` → Before generating any Azure code
- `mcp_azure_mcp_ser_bicepschema` → Before creating Bicep resources  
- `mcp_azure_mcp_ser_extension_az` → For Azure CLI operations
- `mcp_azure_mcp_ser_extension_azd` → For Azure Developer CLI

## ALWAYS: Follow ThorLabs Enterprise Patterns
- **Naming**: `thorlabs-{service}{number}-{region}` (e.g., `thorlabs-kv1-eastus2`)
- **Tags**: Include `Environment: 'Lab'`, `Project: 'ThorLabs'`, `AutoShutdown_Time: '19:00'`, `Layer: '{layer-name}'`, `ManagedBy: 'Bicep'`
- **IaC**: Modular Bicep templates only (never monolithic/Terraform/ARM)
- **Security**: Managed Identity preferred, never hardcode secrets
- **Architecture**: Layered deployment model (Foundation → Security → Compute → Data)

## ENTERPRISE ARCHITECTURE: Modular Infrastructure Layers
**CRITICAL**: Use the layered deployment approach for all infrastructure:

### Layer 1: Foundation (`01-foundation.bicep`)
- **Purpose**: Core infrastructure dependencies
- **Contains**: Resource Groups, Networking (VNet/Subnets), Key Vault, Log Analytics
- **Dependencies**: None (foundation layer)
- **Deploy First**: Always deploy this layer before others

### Layer 2: Security (`02-security.bicep`) 
- **Purpose**: Security monitoring and compliance
- **Contains**: Microsoft Sentinel, Security data connectors, Monitoring
- **Dependencies**: Foundation layer (Log Analytics workspace)
- **Priority**: Deploy immediately after foundation for security engineers

### Layer 3: Compute (`03-compute.bicep`)
- **Purpose**: Virtual machines and compute resources
- **Contains**: VMs, Network interfaces, Auto-shutdown, Monitoring agents
- **Dependencies**: Foundation layer (VNet, Key Vault)

### Layer 4: Data (`04-data.bicep`)
- **Purpose**: Database and storage services  
- **Contains**: SQL Server/Database, Storage Accounts, PostgreSQL, Cosmos DB
- **Dependencies**: Foundation layer (VNet, Key Vault)

## CONTEXT: Creating Modular Bicep Templates
1. **Identify the layer** - Determine which infrastructure layer the resource belongs to
2. Call `mcp_azure_mcp_ser_bestpractices` first
3. Call `mcp_azure_mcp_ser_bicepschema` for resource schemas
4. **Use modules** - Create reusable modules in `infra/modules/` directory
5. **Follow dependency flow** - Foundation → Security → Compute/Data
6. Include parameter validation with `@allowed` decorators
7. Always include proper outputs for dependent layers

## CONTEXT: Deployment Strategy
- **Modular Architecture**: Each layer (foundation, security, compute, data) deploys independently
- **Progressive Deployment**: Foundation → Security → Compute/Data (security priority for security engineers)
- **Simplified Workflows**: Single-click deployment for common scenarios
- **Smart Dependencies**: Workflows auto-deploy foundation if missing
- **Independent Testing**: Each layer validates independently (eliminates monolithic timeouts)
- **Enterprise Benefits**: Faster debugging, selective updates, clear dependencies

### 🎯 Workflow Selection Guide:
- **Security Engineers**: Use "🛡️ Deploy Security (Sentinel)" - gets Sentinel running quickly
- **Full Lab Setup**: Use "🚀 Deploy Complete Lab" - everything deployed progressively
- **Infrastructure Only**: Use "🏗️ Deploy Foundation Only" - core infrastructure for other services
- **Custom Deployments**: Use "🚀 Deploy ThorLabs Modular Infrastructure" - choose specific layers

## CONTEXT: Azure CLI Operations  
1. Use `mcp_azure_mcp_ser_extension_az` for all CLI commands
2. Follow ThorLabs naming conventions
3. Include proper error handling
4. Use `what-if` validation before deployment

## ENTERPRISE WORKFLOW: Modular Deployment Benefits
- **🚀 Faster Iteration**: Deploy only changed layers
- **🛡️ Security First**: Security engineers can deploy foundation + security independently  
- **🔧 Independent Testing**: Each layer tested in isolation
- **📈 Scalability**: Same pattern works for lab → enterprise
- **🎯 Clear Ownership**: Each layer has focused responsibility
- **⚡ No Timeouts**: Eliminates Azure CLI API issues from oversized templates

## PROHIBITED
❌ Monolithic templates ❌ Terraform/ARM templates ❌ Hardcoded secrets ❌ Generic Ubuntu ❌ Bypassing MCP server ❌ Cross-layer dependencies without proper outputs

## CONTEXT FILES
For detailed patterns, attach from `.github/context/`:
- `bicep-patterns.md` - Template examples and schemas
- `azure-mcp-reference.md` - MCP server tool usage
- `security-standards.md` - Security configurations
- `development-guide.md` - Complete development workflows

## QUICK REFERENCE: Modular Deployment Commands

### GitHub Workflow Deployment (Recommended - Just Click!)
**Simplified Single-Purpose Workflows:**
1. **🏗️ Deploy Foundation Only** - Core infrastructure (always run first)
2. **🛡️ Deploy Security (Sentinel)** - Microsoft Sentinel for security engineers  
3. **🚀 Deploy Complete Lab** - Everything at once (foundation + security + compute + data)

**Advanced Modular Workflow:**
- **🚀 Deploy ThorLabs Modular Infrastructure** - Choose specific layers
  - Deploy Layer: `foundation` | `security` | `compute` | `data` | `all-layers`
  - Environment: `lab` | `dev` | `staging`

### CLI Deployment (Alternative - requires workflow permissions)
```bash
# Deploy foundation only (prerequisite for all others)
gh workflow run deploy-modular.yml --field deployLayer=foundation --field environment=lab

# Deploy security layer (Microsoft Sentinel - priority for security engineers)  
gh workflow run deploy-modular.yml --field deployLayer=security --field environment=lab

# Deploy compute layer (Virtual machines)
gh workflow run deploy-modular.yml --field deployLayer=compute --field environment=lab

# Deploy data layer (Databases and storage)
gh workflow run deploy-modular.yml --field deployLayer=data --field environment=lab

# Deploy all layers progressively
gh workflow run deploy-modular.yml --field deployLayer=all-layers --field environment=lab
```

### Local Testing
```bash
# Test template compilation
az bicep build --file infra/01-foundation.bicep --stdout > /dev/null
az bicep build --file infra/02-security.bicep --stdout > /dev/null

# Validate deployment (what-if)
az deployment sub what-if --location eastus2 --template-file infra/01-foundation.bicep
```

### Current File Structure
```
infra/
├── 01-foundation.bicep    # Core infrastructure (RG, VNet, KeyVault, Logs)
├── 02-security.bicep      # Microsoft Sentinel and security monitoring
├── 03-compute.bicep       # Virtual machines and compute resources  
├── 04-data.bicep          # Databases and storage services
└── modules/               # Reusable Bicep modules
    ├── networking.bicep   # VNet and subnets
    ├── keyvault.bicep     # Key Vault configuration
    └── log-analytics.bicep # Log Analytics workspace
```
