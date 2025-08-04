# VS Code Testing Commands for ThorLabs Infrastructure

## Quick Testing via Command Palette (Ctrl+Shift+P):

### 1. Bicep: Build
- Compiles your .bicep files to ARM JSON
- Shows compilation errors immediately
- Use on any .bicep file

### 2. Bicep: Deploy  
- Deploys directly from VS Code
- Prompts for parameters
- Shows deployment progress

### 3. Azure: Sign In
- Authenticate to your Azure subscription
- Required before deployment commands

### 4. Azure Resource Groups: Create Deployment
- Right-click any .bicep file
- Choose "Deploy to Resource Group"
- Visual deployment with progress

## Testing Workflow:

1. Open any .bicep file (e.g., infra/lab.bicep)
2. Save file (Ctrl+S) - auto-validates syntax
3. Command Palette > "Bicep: Build" - validates compilation
4. Command Palette > "Azure: Sign In" - authenticate
5. Right-click .bicep file > "Deploy to Resource Group" - test deploy

## What-If Analysis:
1. Right-click .bicep file
2. Choose "What-If" from context menu
3. See what would change without deploying

## Quick Validation:
- Any syntax errors show as red squiggles
- Hover over resources for documentation
- IntelliSense provides parameter suggestions
