# ThorLabs Enhanced Lab Environment Guide

## 🚀 Quick Start

### Automated Deployment (Recommended)
1. **Fork/Clone this repository**
2. **Set up GitHub Actions secrets** (see [GitHub Secrets Checklist](GITHUB_SECRETS_CHECKLIST.md))
3. **Push to main branch** - Complete lab environment deploys automatically
4. **Monitor deployment** in GitHub Actions tab

### Manual Deployment
```bash
# Interactive deployment with options
./scripts/deploy-lab.sh

# Or direct Azure CLI deployment
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters @infra/master-deployment.parameters.json \
               adminPassword="YourSecurePassword123!"
```

## 📋 Enhanced Infrastructure Overview

### Core Infrastructure (Always Deployed)
- **🐧 Ubuntu 22.04 LTS VM** (`thorlabs-vm1-eastus2`)
  - General purpose development workstation
  - SSH access enabled
  - Azure Monitor agent installed
  
- **🪟 Windows Server 2022 VM** (`thorlabs-vm2-eastus2`)
  - Windows development and testing
  - RDP access enabled
  - Azure Monitor agent installed

- **🌐 Networking**
  - Virtual Network: `10.10.0.0/16`
  - Compute Subnet: `10.10.1.0/24` (VMs)
  - Services Subnet: `10.10.2.0/24` (PaaS services)
  - Network Security Group with SSH/RDP/HTTP/HTTPS rules

- **💾 Storage Account** (`thorlabsstXeastus2`)
  - Standard LRS for cost optimization
  - Containers: `scripts`, `artifacts`
  - Service endpoint integration

- **🔐 Key Vault** (`thorlabs-kv1-eastus2`)
  - Secure secrets management
  - VM credentials stored automatically
  - RBAC enabled

- **📊 Log Analytics Workspace** (`thorlabs-logs1-eastus2`)
  - Centralized logging and monitoring
  - VM monitoring enabled
  - 30-day retention for cost control

### Optional Services

#### Container Services (`deployContainerServices=true`)
- **🐳 Azure Container Registry** (`thorlabsacr1eastus2`)
  - Private container image registry
  - Basic SKU for cost optimization
  
- **📦 Azure Container Instances**
  - On-demand container hosting
  - Sample NGINX container deployed
  
- **🚀 Azure Container Apps Environment**
  - Modern serverless container platform
  - Sample "Hello World" app deployed
  - Auto-scaling configured

#### Database Services (`deployDatabaseServices=true`)
- **🗄️ Azure SQL Database**
  - Basic SKU for lab workloads
  - Firewall configured for Azure services
  
- **🐘 PostgreSQL Flexible Server**
  - Burstable SKU for cost optimization
  - Sample database created
  
- **🌍 Azure Cosmos DB**
  - Serverless configuration
  - Free tier enabled
  - Sample container with partition key

## 🎛️ Deployment Options

### GitHub Actions Workflow
The enhanced workflow (`deploy-enhanced.yml`) provides:

- **Validation Phase**: Template compilation and validation
- **Deployment Types**:
  - `core`: Basic infrastructure only
  - `full`: All services enabled
  - `validation-only`: Test templates without deployment
- **Custom Options**: Choose specific services to deploy
- **VM Sizing**: Select from cost-optimized to performance SKUs
- **Post-deployment Testing**: Automatic resource validation
- **Deployment Summary**: Detailed results and connection info

### Interactive Script Deployment
```bash
./scripts/deploy-lab.sh
```

Features:
- 🔍 **Prerequisites check** (Azure CLI, Bicep, login status)
- 🧪 **Template validation** before deployment
- 🎯 **Interactive configuration** (deployment type, VM size, passwords)
- 📋 **Deployment summary** and confirmation
- ✅ **Post-deployment information** (connection details, costs)

## 🛠️ Management Operations

### Lab Management Script
```bash
./scripts/manage-lab.sh <command>
```

Available commands:
- `show-status`: Detailed status of all resources
- `start-vms`: Start all virtual machines
- `stop-vms`: Stop all VMs (deallocate to save costs)
- `restart-vms`: Restart all virtual machines
- `connect-info`: Get connection details and commands
- `show-costs`: Cost information and optimization tips
- `cleanup`: DELETE entire lab environment

### Examples
```bash
# Check lab status
./scripts/manage-lab.sh show-status

# Stop VMs to save costs
./scripts/manage-lab.sh stop-vms

# Get connection information
./scripts/manage-lab.sh connect-info

# Show cost optimization tips
./scripts/manage-lab.sh show-costs
```

## 🔗 Connection Information

### SSH to Ubuntu VM
```bash
ssh thorlabsadmin@<ubuntu-public-ip>
```

### RDP to Windows VM
```bash
mstsc /v:<windows-public-ip>
```

### Service Endpoints
- **Container Registry**: `thorlabsacr1eastus2.azurecr.io`
- **SQL Server**: `thorlabs-sql1-eastus2.database.windows.net`
- **PostgreSQL**: `thorlabs-pg1-eastus2.postgres.database.azure.com`
- **Storage Account**: `https://thorlabsst1eastus2.blob.core.windows.net/`
- **Key Vault**: `https://thorlabs-kv1-eastus2.vault.azure.net/`

## 💰 Cost Management

### Auto-Shutdown Configuration
- ⏰ **Time**: 7:00 PM Eastern Time
- 🗓️ **Frequency**: Daily
- 💾 **Action**: Deallocate (stop billing for compute)
- 🏷️ **Tags**: `AutoShutdown_Time` and `AutoShutdown_TimeZone`

### Cost Optimization Tips
1. **Stop VMs when not in use**: `./scripts/manage-lab.sh stop-vms`
2. **Use Basic SKUs**: Optimized for lab workloads
3. **Monitor usage**: Azure Cost Management portal
4. **Storage optimization**: LRS replication, appropriate access tiers
5. **Database optimization**: Basic/Burstable SKUs, serverless where available

### Estimated Monthly Costs (with auto-shutdown)
- **Core Infrastructure**: ~$30-50 USD
- **With Container Services**: ~$40-60 USD  
- **With Database Services**: ~$50-80 USD
- **Full Deployment**: ~$60-100 USD

*Costs vary by region and usage patterns. Auto-shutdown reduces compute costs by ~65%.*

## 🏗️ Architecture Patterns

### Network Segmentation
```
Virtual Network (10.10.0.0/16)
├── Compute Subnet (10.10.1.0/24)
│   ├── Ubuntu VM
│   └── Windows VM
└── Services Subnet (10.10.2.0/24)
    ├── Storage Account (service endpoint)
    ├── Key Vault (service endpoint)
    └── SQL Database (service endpoint)
```

### Security Configuration
- **🔒 Key Vault**: RBAC-enabled, network-restricted
- **🛡️ Network Security Groups**: Minimal required ports
- **🔐 Storage**: No public blob access, service endpoints
- **📊 Monitoring**: Azure Monitor agents on all VMs
- **🏷️ Tagging**: Consistent governance tags

### Scalability Considerations
- **VM Sizes**: Easily configurable via parameters
- **Storage**: Can scale to Premium SSDs for performance
- **Databases**: Can upgrade to higher SKUs
- **Containers**: Auto-scaling configured in Container Apps
- **Networking**: Subnet space allows for expansion

## 🧪 Testing Scenarios

### Development Workloads
- **Source Control**: Git repositories on Ubuntu VM
- **Development Tools**: VS Code, Docker, various SDKs
- **Testing**: Local application development and testing

### Container Workloads  
- **Image Building**: Docker on Ubuntu VM + ACR
- **Container Hosting**: ACI for simple workloads
- **Microservices**: Container Apps for modern applications

### Database Testing
- **SQL Workloads**: Full SQL Server capabilities
- **NoSQL**: Cosmos DB for document/graph databases  
- **PostgreSQL**: Open-source database testing

### Networking Testing
- **Multi-tier Applications**: Web/app/data tier separation
- **Service Communication**: VNet integration testing
- **Hybrid Scenarios**: VPN gateway testing (additional setup required)

## 📖 Additional Resources

- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Cost Management](https://docs.microsoft.com/en-us/azure/cost-management-billing/)
- [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/)
- [Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/)

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Failures
1. **Check prerequisites**: Azure CLI, login status, permissions
2. **Validate templates**: `./scripts/deploy-lab.sh` includes validation
3. **Review deployment logs**: Azure portal > Deployments
4. **Check quotas**: Ensure sufficient quota for selected VM sizes

#### Connection Issues
1. **VM not accessible**: Check VM status and NSG rules
2. **Public IP not assigned**: Verify static IP allocation
3. **Password issues**: Reset VM password via Azure portal

#### Cost Management
1. **Unexpected costs**: Check auto-shutdown configuration
2. **Resource cleanup**: Use `./scripts/manage-lab.sh cleanup`
3. **Monitor usage**: Azure Cost Management + Billing

### Support Resources
- **Azure Documentation**: Official Microsoft documentation
- **Azure Support**: Create support tickets for Azure-specific issues
- **Community Forums**: Stack Overflow, Azure forums
- **GitHub Issues**: Report repository-specific issues

---

## 🎯 Next Steps

1. **Deploy your lab**: Choose deployment method (automated or manual)
2. **Explore services**: Test different Azure services in your environment
3. **Customize configuration**: Modify templates for your specific needs
4. **Monitor costs**: Set up budget alerts in Azure Cost Management
5. **Iterate and improve**: Use Infrastructure as Code for consistent deployments
