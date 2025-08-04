# ThorLabs Lab - Quick Reference Card

## 🚀 Quick Deploy Commands

```bash
# Interactive guided deployment (recommended)
./scripts/deploy-lab.sh

# Direct core deployment (basic lab)
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters adminPassword="YourPassword123!"

# Deploy with Sentinel security monitoring
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters enableSentinel=true adminPassword="YourPassword123!"
```

## ⚙️ Management Commands

```bash
# Check lab status
./scripts/manage-lab.sh show-status

# Start all VMs
./scripts/manage-lab.sh start-vms

# Stop all VMs (save costs)
./scripts/manage-lab.sh stop-vms

# Get connection info
./scripts/manage-lab.sh connect-info

# Show cost information  
./scripts/manage-lab.sh show-costs

# Delete everything
./scripts/manage-lab.sh cleanup
```

## � Cost Optimization

| VM Size | Monthly Cost | Use Case |
|---------|--------------|----------|
| **Standard_B1s** | ~$8 | Basic testing, cheapest option |
| **Standard_B2s** | ~$30 | Recommended for development |
| **Standard_DS1_v2** | ~$25 | Balanced performance |

**Total Lab Cost Estimates (with auto-shutdown):**
- **Core Lab**: $15-35/month
- **Core + Containers**: $25-50/month  
- **Full Lab**: $40-70/month

## 🔗 Connection Templates

```bash
# SSH to Ubuntu VM
ssh thorlabsadmin@<ubuntu-public-ip>

# RDP to Windows VM  
mstsc /v:<windows-public-ip>
```

## � Lab Components

### Core Infrastructure (Always Deployed)
- Ubuntu 22.04 LTS VM + Windows Server 2022 VM
- Virtual Network with security groups
- Storage Account + Key Vault
- Log Analytics Workspace
- Auto-shutdown at 7 PM ET

### Optional Components
- **Sentinel**: Security monitoring (+$5-10/month)
- **Container Services**: ACR + Container Instances (+$10-15/month)
- **Database Services**: SQL Database + PostgreSQL (+$15-25/month)

## 🏷️ Resource Naming Convention

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| **Virtual Machine** | `thorlabs-vm{n}-{region}` | `thorlabs-vm1-eastus2` |
| **Storage Account** | `thorlabs{service}{n}{region}` | `thorlabsst1eastus2` |
| **Network** | `thorlabs-{service}{n}-{region}` | `thorlabs-vnet1-eastus2` |
| **Container Registry** | `thorlabs{service}{n}{region}` | `thorlabsacr1eastus2` |
| **Database** | `thorlabs-{service}{n}-{region}` | `thorlabs-sql1-eastus2` |

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| **Deployment fails** | Check `./scripts/deploy-lab.sh` validation |
| **Can't connect to VM** | Check VM status: `./scripts/manage-lab.sh show-status` |
| **High costs** | Stop VMs: `./scripts/manage-lab.sh stop-vms` |
| **Template errors** | Validate: `az bicep build --file infra/*.bicep` |
| **Permission errors** | Check Azure RBAC and subscription access |

## 📱 Portal Quick Links

- **Resource Group**: `https://portal.azure.com/#@/resource/subscriptions/{sub-id}/resourceGroups/thorlabs-rg`
- **Cost Management**: `https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview`
- **Azure Monitor**: `https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/overview`

## 🎯 Common Workflows

### Development Setup
1. Deploy core lab: `./scripts/deploy-lab.sh` → Core
2. Connect to Ubuntu: `ssh thorlabsadmin@<ip>`
3. Install dev tools: `sudo apt update && sudo apt install git docker.io`

### Container Testing  
1. Deploy with containers: Enable container services in deployment
2. Login to ACR: `az acr login --name thorlabsacr1eastus2`
3. Build/push images: `docker build . -t thorlabsacr1eastus2.azurecr.io/myapp:latest`

### Database Development
1. Deploy with databases: Enable database services in deployment  
2. Connect to SQL: Use connection string from deployment output
3. Create schemas: Use Azure Data Studio or SSMS

### Cost Management
1. Monitor: `./scripts/manage-lab.sh show-costs`
2. Daily shutdown: Auto-configured at 7 PM ET
3. Manual stop: `./scripts/manage-lab.sh stop-vms`
4. Cleanup: `./scripts/manage-lab.sh cleanup` (when done)

---
**💡 Tip**: Bookmark this page for quick reference during lab operations!
