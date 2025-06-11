# GitHub Copilot Instructions for ThorLabs Repository

This document provides comprehensive guidelines for GitHub Copilot suggestions and contributors working on the ThorLabs Azure lab environment repository.

## Core Principles

### 1. Continuous Improvement and Adaptive Evolution

The ThorLabs repository is committed to continuous improvement through flexible deployments and evolving best practices while maintaining the core lab mission as the primary focus:

- **Lab Mission First**: All changes and improvements must support the fundamental goal of providing a reliable, cost-effective Azure lab environment for learning and experimentation
- **Flexible Deployment Strategies**: Support multiple deployment approaches (automated GitHub Actions, manual CLI, modular Bicep templates) to accommodate different learning styles and use cases
- **Evolving Best Practices**: Regularly update templates, documentation, and workflows based on Azure service improvements, security updates, and community feedback
- **Incremental Enhancement**: Prioritize small, tested improvements over large architectural changes to maintain stability and reliability
- **Community-Driven Growth**: Welcome contributions that align with lab objectives while maintaining strict quality and documentation standards
- **Backward Compatibility**: Ensure existing deployments continue to function when introducing new features or improvements

### 2. Microsoft/Azure Native Technology Stack
All suggestions and implementations must prioritize Microsoft/Azure native tools and technologies:

- **Infrastructure as Code**: Use Bicep templates exclusively (not Terraform or ARM)
- **Shell Scripting**: Use PowerShell for Windows environments, Azure CLI for cross-platform operations
- **Operating Systems**: 
  - Windows Server (2019/2022) for domain services and enterprise workloads
  - Ubuntu for Azure for Linux workloads (not generic Ubuntu distributions)
- **Azure Services**: Prioritize Azure-native solutions over third-party alternatives
- **Development Tools**: Visual Studio Code, Azure CLI, Bicep CLI

### 3. Strict Naming Conventions
All Azure resources MUST follow the established naming scheme:

**Format**: `thorlabs-{service}{number}-{region}`

**Examples**:
- `thorlabs-vm1-eastus2` (Ubuntu server)
- `thorlabs-vm2-eastus2` (Windows server)
- `thorlabs-db1-eastus2` (Database)
- `thorlabs-app1-eastus2` (Web application)

**Service Abbreviations**:
- `vm` - Virtual Machine
- `db` - Database
- `app` - Web Application/App Service
- `st` - Storage Account
- `kv` - Key Vault
- `rg` - Resource Group
- `vnet` - Virtual Network
- `nsg` - Network Security Group
- `pip` - Public IP Address

### 4. Directory Structure Requirements
Maintain the established directory structure and update documentation when adding new components:

```
ThorLabs/
├── .github/
│   ├── workflows/          # GitHub Actions workflows
│   └── COPILOT_INSTRUCTIONS.md
├── docs/                   # All documentation
│   ├── INSTRUCTIONS.md     # Step-by-step deployment guide
│   ├── GITHUB_SECRETS_CHECKLIST.md
│   ├── DEPLOY_WORKFLOW.md
│   └── *.md               # Additional documentation
├── infra/                  # Main Bicep templates
│   ├── main.bicep         # Ubuntu server template
│   └── main.parameters.json
├── bicep/                  # Additional Bicep templates
│   ├── windows-server-base.bicep
│   └── *.parameters.json
├── scripts/                # PowerShell and shell scripts
├── policies/               # Azure Policy definitions
├── README.md              # Project overview and quick reference
└── history.md             # Manual command history log
```

## Pull Request and Code Review Requirements

### Mandatory Checks for All Pull Requests

1. **Naming Convention Validation**
   - All new Azure resources must follow `thorlabs-{service}{number}-{region}` format
   - Variable names and parameters should reflect this convention
   - File names should be descriptive and follow kebab-case

2. **Documentation Updates**
   - Any infrastructure changes must be referenced in the appropriate README section
   - New scripts or commands must be documented in the `docs/` folder
   - Update `docs/REPO_GUIDE.md` if directory structure changes

3. **Microsoft/Azure Native Compliance**
   - No third-party Infrastructure as Code tools (Terraform, CloudFormation, etc.)
   - Use Azure CLI over REST API calls where possible
   - Prefer Azure-native services over external alternatives

4. **Security Best Practices**
   - Never commit secrets, passwords, or subscription IDs
   - Use GitHub Actions secrets for sensitive values
   - Follow principle of least privilege for resource access
   - Include appropriate Network Security Group rules

### Workflow and Automation Requirements

1. **Bicep Template Standards**
   - Templates must compile without errors using `bicep build`
   - Include parameter validation with `@allowed` decorators where appropriate
   - Use meaningful parameter descriptions and default values
   - Include resource tagging for cost management (AutoShutdown_Time, Environment, etc.)

2. **GitHub Actions Workflow Standards**
   - All workflows must include Azure login and subscription setting
   - Use verbose output for deployment operations
   - Include template validation steps before deployment
   - Deploy both Ubuntu and Windows environments for infrastructure changes

3. **Script Documentation Requirements**
   - All PowerShell scripts must include comment-based help
   - Include parameter validation and error handling
   - Log important actions to enable troubleshooting
   - Test scripts in isolated environments before committing

## Specific Technology Guidelines

### Bicep Templates
```bicep
// Always include resource tagging
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  tags: {
    Environment: 'Lab'
    Project: 'ThorLabs'
    AutoShutdown_Time: '19:00'
    AutoShutdown_TimeZone: 'Eastern Standard Time'
  }
  // ... rest of configuration
}

// Use parameter validation
@allowed([
  'Standard_B1s'
  'Standard_B2s'
  'Standard_D2s_v3'
])
param vmSize string = 'Standard_B1s'
```

### PowerShell Scripts
```powershell
<#
.SYNOPSIS
    Brief description of the script purpose
.DESCRIPTION
    Detailed description of what the script does
.PARAMETER ParameterName
    Description of the parameter
.EXAMPLE
    .\script-name.ps1 -ParameterName "value"
.NOTES
    Author: [Author Name]
    Date: [Date]
    Version: [Version]
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredParameter
)

# Always check for administrator privileges when needed
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires administrator privileges. Please run as administrator."
    exit 1
}
```

### Azure CLI Commands
```bash
# Always set subscription context
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Use verbose output for deployment operations
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json \
  --verbose

# Include proper error handling
if [ $? -ne 0 ]; then
    echo "Deployment failed"
    exit 1
fi
```

## Azure-Specific Copilot Instructions

When using GitHub Copilot for Azure in this repository, always follow these additional requirements:

- **Use Azure-Native Tools and Services**: All code, scripts, and workflows must use Microsoft/Azure native technologies (Bicep, Azure CLI, PowerShell for Windows, Azure Policy, etc.). Do not use Terraform, ARM templates, or third-party IaC tools.
- **Invoke Azure Best Practices**: When generating Azure code, scripts, or workflows, always reference and apply the latest Azure code generation and deployment best practices. Use the Copilot tools for Azure code gen and deployment best practices if available.
- **Strict Naming and Tagging**: Ensure all Azure resources, variables, and parameters follow the `thorlabs-{service}{number}-{region}` naming convention and include required tags (`Environment`, `Project`, `AutoShutdown_Time`, `AutoShutdown_TimeZone`).
- **Security and Compliance**: Never commit secrets or sensitive values. Use GitHub Actions secrets and Azure Key Vault for secret management. Always follow the principle of least privilege and include appropriate NSG/firewall rules.
- **Documentation and Validation**: Document all Azure-related changes in the appropriate `README.md` and `docs/` files. Validate Bicep templates and scripts before committing.
- **Reference Patterns**: Use the provided Bicep, PowerShell, and Azure CLI code patterns as templates for all new Azure resources and automation.

> **Note:** For any Azure Functions or Azure Static Web Apps, always check and apply the respective Copilot best practices tools before generating code.

## File and Change Documentation Requirements

### README.md Updates Required For:
- New Azure services or resources
- Changes to naming conventions
- New workflow behaviors
- Security or access requirement changes

### docs/ Folder Updates Required For:
- New deployment procedures
- Modified scripts or commands
- Troubleshooting guides
- Security configuration changes

### history.md Updates Required For:
- Manual Azure CLI commands executed
- One-time configuration changes
- Administrative actions performed outside of automation

## Cost Management and Resource Governance

### Required Resource Tags
All Azure resources must include these tags:
- `Environment`: "Lab"
- `Project`: "ThorLabs"
- `AutoShutdown_Time`: "19:00" (or appropriate time)
- `AutoShutdown_TimeZone`: "Eastern Standard Time"

### Cost Control Practices
- Use appropriate VM sizes (prefer B-series for development)
- Implement auto-shutdown policies
- Use managed disks with appropriate performance tiers
- Deallocate VMs when not in use

## Security and Compliance

### Network Security
- Restrict RDP/SSH access to specific IP ranges in production
- Use Network Security Groups with least privilege access
- Implement proper firewall rules for domain services

### Secret Management
- Store all sensitive values in GitHub Actions secrets
- Never commit passwords or keys to repository
- Use Azure Key Vault for application secrets
- Rotate credentials regularly

### Access Control
- Follow principle of least privilege
- Use Azure RBAC for resource access
- Implement proper service account permissions
- Regular access reviews and cleanup

## Common Patterns and Templates

When suggesting code, prioritize these established patterns from the repository:

1. **Bicep Parameter Pattern**:
   ```bicep
   param location string = resourceGroup().location
   param vmName string = 'thorlabs-vm1-eastus2'
   @secure()
   param adminPassword string
   ```

2. **GitHub Actions Workflow Pattern**:
   ```yaml
   env:
     AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
     ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
   ```

3. **PowerShell Error Handling Pattern**:
   ```powershell
   try {
       # Operation
   }
   catch {
       Write-Error "Operation failed: $($_.Exception.Message)"
       exit 1
   }
   ```

## Contribution Workflow

1. **Before Making Changes**:
   - Review existing documentation in `docs/` folder
   - Ensure changes align with Microsoft/Azure native approach
   - Validate Bicep templates compile successfully
   - Check naming conventions compliance

2. **During Development**:
   - Test scripts in isolated environments
   - Use consistent error handling patterns
   - Include appropriate logging and verbose output
   - Follow established directory structure

3. **Before Pull Request**:
   - Update relevant documentation in `README.md` and `docs/`
   - Add new commands to `history.md` if executed manually
   - Validate all Bicep templates build successfully
   - Ensure workflows pass syntax validation

This document should be referenced for all code suggestions and contributions to maintain consistency and quality across the ThorLabs repository.
