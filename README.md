# ThorLabs Lab Environment: Azure Pipeline with Bicep

## Quick Start

Deploy the ThorLabs enhanced lab environment with comprehensive Azure services for stable testing and development.

### 🚀 **Enhanced Automated Deployment (Recommended)**
1. **Set up GitHub Actions secrets** - See [`docs/GITHUB_SECRETS_CHECKLIST.md`](docs/GITHUB_SECRETS_CHECKLIST.md)
2. **Choose deployment type** - Push to main branch or use workflow dispatch:
   - **Core Lab**: VMs, networking, storage, monitoring (~$30-50/month)
   - **Full Lab**: Core + containers + databases (~$60-100/month)
   - **Custom**: Choose specific services
3. **Monitor deployment** - Check GitHub Actions tab for real-time progress

### 🛠️ **Interactive Manual Deployment**
```bash
# Interactive deployment with guided setup
./scripts/deploy-lab.sh

# Or direct Azure CLI deployment
az deployment sub create \
  --location eastus2 \
  --template-file infra/master-deployment.bicep \
  --parameters adminPassword="YourSecurePassword123!"
```

### 📊 **Lab Management**
```bash
# Check status of all resources
./scripts/manage-lab.sh show-status

# Start/stop VMs to manage costs
./scripts/manage-lab.sh stop-vms

# Get connection information
./scripts/manage-lab.sh connect-info
```

**📖 For comprehensive setup instructions, see [`docs/ENHANCED_LAB_GUIDE.md`](docs/ENHANCED_LAB_GUIDE.md)**

---

## Purpose & How to Use This Repo

This repository helps you automate, document, and control your Azure lab environment using Infrastructure as Code (IaC) with Bicep templates and GitHub Actions. It is organized for clarity, security, and repeatability:

- **Start here in `README.md`** for a high-level overview, project goals, and naming conventions.
- **See the `docs/` folder** for detailed instructions (`INSTRUCTIONS.md`) and secrets management (`GITHUB_SECRETS_CHECKLIST.md`).
- **All Bicep templates and parameters** are in the `infra/` folder.
- **Document all manual commands** in `history.md` for traceability.

---

## Goals

- Deploy and manage Azure resources for a lab environment using Bicep templates
- Automate deployments with an Azure Pipeline
- Keep costs low by shutting down or deallocating resources when not needed
- Enforce governance and compliance through Azure Policy definitions
- Document all PowerShell commands and maintain a history file for reference
- Use a consistent, descriptive naming scheme for all resources

---

## Resource Naming Scheme

**Format:** `{projectname}-{service}{number}-{region}`

- `projectname`: Always `thorlabs` for this environment
- `service`: Short name for the Azure service (e.g., `db` for database, `vm` for virtual machine)
- `number`: Increment for each resource of the same type
- `region`: Azure region (e.g., `eastus`)

**Example:**

```
thorlabs-db1-eastus
thorlabs-vm2-eastus
```

---

## Enhanced Repository Structure

- [`README.md`](README.md) — High-level overview and quick start guide  
- [`docs/ENHANCED_LAB_GUIDE.md`](docs/ENHANCED_LAB_GUIDE.md) — **📖 Comprehensive guide for enhanced lab environment**
- [`docs/INSTRUCTIONS.md`](docs/INSTRUCTIONS.md) — Legacy step-by-step deployment instructions
- [`docs/GITHUB_SECRETS_CHECKLIST.md`](docs/GITHUB_SECRETS_CHECKLIST.md) — GitHub Actions secrets setup
- [`.github/workflows/deploy-enhanced.yml`](.github/workflows/deploy-enhanced.yml) — **🚀 Enhanced deployment workflow with options**
- [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) — Legacy deployment workflow
- [`infra/master-deployment.bicep`](infra/master-deployment.bicep) — **🏗️ Master orchestration template**
- [`infra/enhanced-lab.bicep`](infra/enhanced-lab.bicep) — Enhanced core infrastructure
- [`infra/container-services.bicep`](infra/container-services.bicep) — Container workloads (ACR, ACI, Container Apps)
- [`infra/database-services.bicep`](infra/database-services.bicep) — Database services (SQL, PostgreSQL, Cosmos)
- [`scripts/deploy-lab.sh`](scripts/deploy-lab.sh) — **🛠️ Interactive deployment script**
- [`scripts/manage-lab.sh`](scripts/manage-lab.sh) — **⚙️ Lab management operations**
- [`bicep/`](bicep/) — Legacy Bicep templates (for reference)
- [`policies/`](policies/) — Azure Policy definitions for governance

## Enhanced Lab Environment

The enhanced GitHub Actions workflow provides flexible deployment options for comprehensive Azure testing:

### 🏗️ **Core Infrastructure** (Always Deployed)
- **Ubuntu 22.04 LTS VM** (`thorlabs-vm1-eastus2`) - Development workstation with SSH access
- **Windows Server 2022 VM** (`thorlabs-vm2-eastus2`) - Windows development with RDP access  
- **Virtual Network** - Segmented subnets for compute and services (10.10.0.0/16)
- **Storage Account** - Secure blob storage with service endpoints
- **Key Vault** - Centralized secrets management with RBAC
- **Log Analytics Workspace** - Monitoring and logging for all resources

### 🐳 **Container Services** (Optional)
- **Azure Container Registry** - Private container image registry
- **Container Instances** - On-demand container hosting
- **Container Apps Environment** - Modern serverless container platform

### 🗄️ **Database Services** (Optional)  
- **Azure SQL Database** - Managed SQL Server with firewall rules
- **PostgreSQL Flexible Server** - Open-source database with sample DB
- **Cosmos DB** - NoSQL database with serverless configuration

### 💰 **Cost Optimization**
- **Auto-shutdown** at 7 PM ET daily for cost control
- **Basic SKUs** optimized for lab workloads  
- **Estimated costs**: $30-100 USD/month depending on services enabled
- **Management scripts** for easy start/stop operations

---

## Lab Environment Cleanup

The GitHub Actions workflow in [`.github/workflows/cleanup-lab.yml`](.github/workflows/cleanup-lab.yml) provides a manual cleanup option to delete the entire lab environment. This workflow:

- **Manual triggering only** - Requires explicit user action via the Actions UI
- **Confirmation required** - Users must type "DELETE" to confirm the operation
- **Complete cleanup** - Removes the `thorlabs-rg` resource group and all contained resources
- **Handles edge cases** - Gracefully handles scenarios where the resource group doesn't exist

To use the cleanup workflow:
1. Go to the **Actions** tab in your repository
2. Select "Cleanup Azure Lab Environment" workflow
3. Click "Run workflow" button
4. Type "DELETE" in the confirmation field
5. Click "Run workflow" to execute

---

## Deployment Monitoring

The GitHub Actions workflow in [`.github/workflows/monitor.yml`](.github/workflows/monitor.yml) automatically monitors deployment failures and creates GitHub issues for rapid incident response. This workflow:

- **Automatic Failure Detection** - Triggers when the "Deploy Azure Lab Environment" workflow fails
- **Intelligent Issue Creation** - Creates detailed GitHub issues with failure context and troubleshooting guidance
- **Security-Conscious Logging** - Provides error summaries without exposing sensitive information
- **Streamlined Assignment** - Labels issues with `ci-failure` and assigns to `ghcp-agent` for Software Agent review

The monitoring workflow helps ensure deployment failures are quickly identified and addressed, supporting the lab environment's reliability and continuous improvement goals.

For detailed monitoring configuration and troubleshooting, see [Deployment Monitoring Documentation](docs/MONITOR_WORKFLOW.md).

---

## Deploying Azure Policies

This repository includes Azure Policy definitions in the `policies/` folder to enforce governance and compliance. Policies can be deployed using:

- **Bicep templates** (recommended) - Infrastructure as Code approach with version control
- **Azure CLI** - Manual deployment using JSON definitions
- **GitHub Actions** - Automated deployment via CI/CD pipeline

**Key Benefits:**
- Enforce VM auto-shutdown tags for cost control (automatically sets required tags)
- Ensure consistent governance across resources
- Automated compliance monitoring

For detailed policy deployment instructions, examples, and troubleshooting, see [`policies/README.md`](policies/README.md).

---

## Contributor Guidelines

This repository follows strict guidelines to ensure consistency, security, and Microsoft/Azure native approach:

- **Naming Conventions**: All Azure resources must follow the `thorlabs-{service}{number}-{region}` format
- **Technology Stack**: Use only Microsoft/Azure native tools (Bicep, PowerShell, Azure CLI, Windows Server, Ubuntu for Azure)
- **Documentation Requirements**: All significant changes must be documented in README and the `docs/` folder
- **Code Review Standards**: Pull requests are automatically checked for naming convention compliance and documentation updates

For comprehensive guidelines, see [GitHub Copilot Instructions](.github/COPILOT_INSTRUCTIONS.md).

---

## Security & Best Practices

- **Never commit real secrets, passwords, or subscription IDs to the repo.** Use placeholders and store sensitive values as GitHub Actions secrets. For a detailed checklist, see [GitHub Secrets Checklist](docs/GITHUB_SECRETS_CHECKLIST.md).
- Reference secrets in your workflows using `${{ secrets.SECRET_NAME }}`.
- Update documentation and checklists as your environment evolves.

---

For detailed instructions and secrets management, see the `docs/` folder.
