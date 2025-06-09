# ThorLabs Lab Environment: Instructions

This document provides step-by-step instructions for deploying and managing your Azure lab environment using Bicep templates and GitHub Actions.

---

## Prerequisites

- Visual Studio Code
- Bicep CLI
- Azure CLI
- Azure subscription with permissions to deploy resources

---

## Setup Steps

### 1. Codespaces or Local Clone
- If using Codespaces, skip the clone step.
- If local, clone the repo:
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
az group create --name thorlabs-rg --location eastus2
```

### 4. Deploy a Bicep Template
```bash
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.parameters.json
```

- You can override sensitive parameters (like adminPassword) at deploy time:
  ```bash
  export ADMIN_PASSWORD='yourStrongPasswordHere'
  az deployment group create \
    --resource-group thorlabs-rg \
    --template-file ./infra/main.bicep \
    --parameters adminPassword=$ADMIN_PASSWORD \
    --parameters @./infra/main.parameters.json
  ```

---

## Cost Control: Turning Off Resources

- Deallocate a VM:
  ```bash
  az vm deallocate --resource-group thorlabs-rg --name thorlabs-vm1-eastus2
  ```
- Stop an App Service:
  ```bash
  az webapp stop --resource-group thorlabs-rg --name thorlabs-app1-eastus2
  ```
- List all running VMs:
  ```bash
  az vm list -d -o table
  ```

---

## Documenting Manual Actions

- Add all manual PowerShell or CLI commands to `history.md` in the repo root for traceability.

---

For secrets and workflow setup, see `docs/GITHUB_SECRETS_CHECKLIST.md`.
