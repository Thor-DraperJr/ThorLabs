# ThorLabs Quick Commands

## 🚀 Deploy Lab
```bash
# Deploy complete lab
az deployment group create --resource-group thorlabs-rg --template-file infra/enhanced-lab.bicep --parameters @infra/enhanced-lab.parameters.json

# Deploy by layers
az deployment group create --resource-group thorlabs-rg --template-file infra/01-foundation.bicep
az deployment group create --resource-group thorlabs-rg --template-file infra/02-security.bicep
az deployment group create --resource-group thorlabs-rg --template-file infra/03-compute.bicep
az deployment group create --resource-group thorlabs-rg --template-file infra/04-data.bicep
```

## 🔍 Check Resources
```bash
# List all resources
az resource list --resource-group thorlabs-rg --output table

# Check VMs
az vm list --resource-group thorlabs-rg --output table

# Check storage
az storage account list --resource-group thorlabs-rg --output table
```

## 🛑 Stop/Start VMs  
```bash
# Stop all VMs
az vm deallocate --ids $(az vm list --resource-group thorlabs-rg --query "[].id" --output tsv)

# Start all VMs
az vm start --ids $(az vm list --resource-group thorlabs-rg --query "[].id" --output tsv)
```

## ✅ Validate Templates
```bash
# Test compilation
az bicep build --file infra/enhanced-lab.bicep

# What-if deployment
az deployment group what-if --resource-group thorlabs-rg --template-file infra/enhanced-lab.bicep
```

## 🗑️ Cleanup
```bash
# Delete resource group (everything)
az group delete --name thorlabs-rg --yes --no-wait
```
