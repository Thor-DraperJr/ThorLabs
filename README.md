# ThorLabs Azure Lab Environment

Cybersecurity lab for Azure cloud security learning and testing.

## 🚀 Quick Deploy

```bash
# Create resource group
az group create --name thorlabs-rg --location eastus2

# Deploy lab
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file infra/enhanced-lab.bicep \
  --parameters @infra/enhanced-lab.parameters.json
```

## 📋 Commands

See [`QUICK_COMMANDS.md`](QUICK_COMMANDS.md) for all operations.

## 📁 Structure

```
infra/
├── 01-foundation.bicep    # Core infrastructure
├── 02-security.bicep      # Sentinel & monitoring  
├── 03-compute.bicep       # VMs & compute
├── 04-data.bicep          # Databases & storage
└── enhanced-lab.bicep     # Complete lab deployment
```

## 📚 Documentation

- [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md) - Detailed deployment
- [`docs/SECURITY_COPILOT_SETUP.md`](docs/SECURITY_COPILOT_SETUP.md) - Security Copilot
- [`docs/QUICK_REFERENCE.md`](docs/QUICK_REFERENCE.md) - Quick reference

## 💰 Cost Management

Auto-shutdown configured for 7 PM ET. Estimated costs:
- **Basic Lab**: ~$30-50/month
- **Enhanced Lab**: ~$60-100/month
