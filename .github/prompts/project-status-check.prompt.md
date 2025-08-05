# Project Status Check

Quick health check of ThorLabs project before ending session or making changes.

## Context
@workspace - Current repository state
@azure - Live Azure resource status

## Quick Checks

### Repository Health
- Git status and uncommitted changes
- File count vs. anti-sprawl targets (33 main files)
- Any new bloat or duplicate files

### Azure Resources Status
- Logic Apps connections health
- Key infrastructure resources running
- Any error states or authentication issues

### Development Environment
- Recent terminal commands and outputs
- Any background processes or servers running
- System resources and cleanup needs

## Example Usage
```
Give me a quick status check of the ThorLabs project and Azure resources before I wrap up
```

## Success Indicators
- ✅ Repository clean (33 core files maintained)
- ✅ Azure resources healthy 
- ✅ No authentication errors
- ✅ Git status clean or ready to commit
- ✅ Anti-sprawl protocol maintained
