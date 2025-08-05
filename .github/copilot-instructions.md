# ThorLabs Azure Lab Environment: AI Agent Instructions

## 🚨 ANTI-SPRAWL PROTOCOL: Prevention Over Cleanup
**CRITICAL**: Prevent bloat before it starts. Question EVERY file creation:

### Before Creating ANY File:
1. **"Does this already exist?"** → Search existing files first
2. **"Is this just a wrapper?"** → Use direct commands instead of scripts
3. **"Will this duplicate content?"** → Consolidate into existing files
4. **"Can this be one command?"** → Don't script what's already simple

### Red Flags That Cause Sprawl:
- ❌ **Wrapper Scripts**: If it's just `az` commands, don't script it
- ❌ **Meta Documentation**: Docs about docs, guides about guides
- ❌ **Multiple README files**: One per directory maximum
- ❌ **"Helper" scripts**: Usually unnecessary complexity
- ❌ **Template variations**: One template per purpose, use parameters

### When to Create Files:
- ✅ **Complex multi-step processes** that can't be one command
- ✅ **Reusable templates** with actual parameters
- ✅ **Essential documentation** that doesn't exist elsewhere
- ✅ **Configuration files** for tools that require them

## ALWAYS: Use Microsoft Documentation + Azure CLI First
When working with Azure, **ALWAYS** follow this reliable workflow:
- `mcp_microsoft-doc_microsoft_docs_search` → For current best practices and API versions
- `mcp_azure_mcp_ser_bicepschema` → Before creating Bicep resources  
- `mcp_azure_mcp_ser_extension_az` → For Azure CLI operations and REST API calls
- `mcp_azure_mcp_ser_extension_azd` → For Azure Developer CLI
- **AVOID**: `mcp_azure_mcp_ser_bestpractices` → Unreliable, contradictory documentation

### Proven Azure MCP Server Capabilities
- **Logic App Connection Updates**: Use `az rest` commands to fix "Unauthenticated" connections
- **Resource Management**: Direct REST API calls via `mcp_azure_mcp_ser_extension_az`
- **Connection Authentication**: Update grant types using PUT requests to connection endpoints

## ALWAYS: Follow ThorLabs Enterprise Patterns
- **Naming**: `thorlabs-{service}{number}-{region}` (e.g., `thorlabs-kv1-eastus2`)
- **Tags**: Include `Environment: 'Lab'`, `Project: 'ThorLabs'`, `AutoShutdown_Time: '19:00'`, `Layer: '{layer-name}'`, `ManagedBy: 'Bicep'`
- **IaC**: Modular Bicep templates only (never monolithic/Terraform/ARM)
- **Security**: Managed Identity preferred, never hardcode secrets
- **Architecture**: Layered deployment model (Foundation → Security → Compute → Data)
- **Commands Over Scripts**: Use direct Azure CLI commands instead of wrapper scripts
- **One Source of Truth**: Single template per capability, no duplicates

## MODULAR INFRASTRUCTURE: 4-Layer Architecture
**Foundation → Security → Compute → Data** (deploy in order)

### Layer Files & Dependencies
- **01-foundation.bicep**: Resource Groups, VNet, Key Vault, Log Analytics *(no dependencies)*
- **02-security.bicep**: Microsoft Sentinel, Security monitoring *(needs foundation)*  
- **03-compute.bicep**: VMs, Network interfaces, Auto-shutdown *(needs foundation)*
- **04-data.bicep**: SQL, Storage, PostgreSQL, Cosmos DB *(needs foundation)*

### Bicep Best Practices
1. **Check layer** → Call `mcp_microsoft-doc_microsoft_docs_search` for current best practices
2. **Get schemas** → Call `mcp_azure_mcp_ser_bicepschema` for resource definitions
3. **Use modules** in `infra/modules/` for reusable components
4. **Parameter validation** with `@allowed` decorators
5. **Proper outputs** for layer dependencies
6. **Single purpose**: One template per capability, avoid feature creep
7. **No duplicates**: Check existing templates before creating new ones

## DEPLOYMENT: GitHub Workflows (One-Click)
- **🏗️ Foundation Only**: Core infrastructure first
- **🛡️ Security (Sentinel)**: Priority for security engineers
- **🚀 Complete Lab**: Everything deployed progressively
- **� Modular Infrastructure**: Choose specific layers

## DEVELOPMENT ENVIRONMENT
- **Bash aliases**: 50+ shortcuts (`gs`, `ga`, `gc`, `gp`, `projects`, `c`)
- **Context files**: `.github/context/development-environment.md`
- **Shell**: Loads with `bash -i` providing all aliases

## 📚 LESSONS FROM CLEANUP (Apply Going Forward)
**Root Causes of Sprawl We Eliminated:**

### Script Bloat Pattern:
- **Problem**: Created 330-line script to run `az deployment group create`
- **Solution**: Use Azure CLI directly, document in QUICK_COMMANDS.md
- **Rule**: If it's 3 Azure CLI commands or fewer, no script needed

### Documentation Duplication:
- **Problem**: 4 guides covering same deployment process (921 lines total)
- **Solution**: One guide with clear sections, link don't duplicate
- **Rule**: Write once, reference everywhere

### Template Multiplication:
- **Problem**: 3 storage templates doing identical things
- **Solution**: One template with parameters for variations
- **Rule**: Parameters > Multiple templates

### Meta-Work Trap:
- **Problem**: Created docs about cleanup instead of just cleaning
- **Solution**: Do the work, minimal documentation
- **Rule**: Functionality over process documentation

## PROHIBITED ❌
- **Wrapper Scripts**: No scripts that just run `az` commands
- **Duplicate Templates**: One template per capability only
- **Meta Documentation**: No docs about docs, guides about guides  
- **Multiple READMEs**: Max one per directory
- **Monolithic Templates**: Keep templates focused and modular
- **Terraform/ARM**: Bicep only for Azure infrastructure
- **Hardcoded Secrets**: Use managed identities and Key Vault
- **Generic Ubuntu**: Use specific, security-hardened images
- **Unreliable MCP Tools**: Avoid `mcp_azure_mcp_ser_bestpractices` (contradictory docs)

## ✅ PREFERRED PATTERNS
- **Direct Commands**: `az deployment group create` over wrapper scripts
- **Simple Documentation**: Commands and examples over lengthy guides
- **Template Parameters**: One template with parameters vs multiple templates
- **Consolidated Files**: Merge similar content instead of creating new files

## CONTEXT REFERENCE
**Quick access**: `.github/context/` contains all detailed patterns and procedures

### Local Testing
```bash
# Test template compilation
az bicep build --file infra/01-foundation.bicep --stdout > /dev/null
az bicep build --file infra/02-security.bicep --stdout > /dev/null

# Validate deployment (what-if)
az deployment sub what-if --location eastus2 --template-file infra/01-foundation.bicep
```

### Template Validation Workflow
```bash
# 1. JSON syntax validation (for ARM templates)
python3 -m json.tool template.json > /dev/null

# 2. Azure CLI validation (most reliable)
az deployment group validate --resource-group rg-name --template-file template.json

# 3. ARM template compilation check
az bicep decompile --file template.json --force
```

**Note**: VS Code ARM template warnings are often false positives. Use Azure CLI validation for reliable results.

### Current Clean Structure (Post-Consolidation)
```
ThorLabs/                          # 33 focused files total
├── README.md                      # Simple overview
├── QUICK_COMMANDS.md              # All Azure CLI commands
├── docs/                          # Essential docs only (5 files)
├── infra/                         # Core templates + modules
│   ├── 01-foundation.bicep        # Core infrastructure layer
│   ├── 02-security.bicep          # Security & Sentinel monitoring
│   ├── 03-compute.bicep           # VMs & compute resources  
│   ├── 04-data.bicep              # Databases & storage
│   ├── enhanced-lab.bicep         # Complete lab deployment
│   ├── master-deployment.bicep    # Orchestration template
│   └── modules/                   # Reusable components
├── logicapps/SecCpScuControl/     # Security Copilot Logic Apps (3 files)
└── policies/                      # Azure governance policies
```

**Maintain This Simplicity**: Question every new file against this clean structure.
