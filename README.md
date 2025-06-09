# ThorLabs Lab Environment: Azure Pipeline with Bicep

---

## Purpose

Welcome! This repo is my journey into managing a lab environment in Azure using Infrastructure as Code (IaC) with Bicep templates. The goal: automate, document, and control my Azure resources—while keeping costs low by turning things off when not in use.

This is my first time using Bicep, so everything here is written to be simple, clear, and repeatable. If you’re new to Bicep or Azure pipelines, you’re in the right place.

---

## Goals

- Deploy and manage Azure resources for a lab environment using Bicep templates
- Automate deployments with an Azure Pipeline
- Keep costs low by shutting down or deallocating resources when not needed
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

## Getting Started with Bicep

### Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with permissions to deploy resources

### 1. Clone the Repo

```bash
git clone <your-repo-url>
cd ThorLabs
```

### 2. Authenticate with Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

### 3. Create a Resource Group

```bash
az group create --name thorlabs-lab --location eastus
```

### 4. Deploy a Bicep Template

```bash
az deployment group create \
  --resource-group thorlabs-lab \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.parameters.json
```

- Edit the Bicep and parameter files as needed for your environment.

---

## Cost Control: Turning Off Resources

To keep costs low, deallocate or stop resources when not in use. Here are some common PowerShell/Azure CLI commands:

### Deallocate a Virtual Machine

```bash
az vm deallocate --resource-group thorlabs-lab --name thorlabs-vm1-eastus
```

### Stop an App Service

```bash
az webapp stop --resource-group thorlabs-lab --name thorlabs-app1-eastus
```

### List All Running VMs

```bash
az vm list -d -o table
```

---

## Documenting PowerShell Commands

All PowerShell or CLI commands used for deployments, management, or troubleshooting should be added to `history.md` in the root of this repo. This keeps a running log of what was done, when, and why.

**Example entry in `history.md`:**

```
2025-06-09: Deployed initial lab environment using main.bicep
2025-06-10: Deallocated VM to save costs
```

---

## Next Steps

- Add your Bicep templates to the `infra/` folder
- Update `main.parameters.json` for your environment
- Commit and push changes to trigger your Azure Pipeline (if configured)
- Check `history.md` for a log of all actions

---

## References

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Naming Tool](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

---

Happy automating! If you have downtime, try something new and document it here. That’s how this all started.
