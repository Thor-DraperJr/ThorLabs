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

### 4. Deploy the Lab Environment
```bash
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file ./infra/lab.bicep \
  --parameters @./infra/lab.parameters.json
```

- You can override sensitive parameters (like adminPassword) at deploy time:
  ```bash
  export ADMIN_PASSWORD='yourStrongPasswordHere'
  az deployment group create \
    --resource-group thorlabs-rg \
    --template-file ./infra/lab.bicep \
    --parameters adminPassword=$ADMIN_PASSWORD \
    --parameters @./infra/lab.parameters.json
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

## Script Distribution Using Storage Account

The ThorLabs environment includes a storage account (`thorlabsst1eastus2`) for centralized script distribution to both Windows and Ubuntu VMs. This enables consistent deployment and management of configuration scripts.

### Deploying the Scripts Storage Account

Deploy the storage account using the Bicep template:

```bash
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file ./bicep/scripts-storage.bicep \
  --parameters @./bicep/scripts-storage.parameters.json
```

### Uploading Scripts to Storage

After deployment, upload your scripts to the storage account:

```bash
# Get storage account key for authentication
STORAGE_KEY=$(az storage account keys list \
  --resource-group thorlabs-rg \
  --account-name thorlabsst1eastus2 \
  --query '[0].value' -o tsv)

# Upload a PowerShell script for Windows VMs
az storage blob upload \
  --account-name thorlabsst1eastus2 \
  --account-key $STORAGE_KEY \
  --container-name scripts \
  --name windows-setup.ps1 \
  --file ./scripts/windows-setup.ps1

# Upload a shell script for Ubuntu VMs  
az storage blob upload \
  --account-name thorlabsst1eastus2 \
  --account-key $STORAGE_KEY \
  --container-name scripts \
  --name ubuntu-setup.sh \
  --file ./scripts/ubuntu-setup.sh
```

### Downloading and Executing Scripts on VMs

#### Windows Server VMs

Use PowerShell to download and execute scripts from the storage account:

```powershell
# Set storage account details
$StorageAccountName = "thorlabsst1eastus2"
$ContainerName = "scripts"
$ScriptName = "windows-setup.ps1"

# Get storage account key (requires Azure PowerShell module)
$StorageKey = (Get-AzStorageAccountKey -ResourceGroupName "thorlabs-rg" -Name $StorageAccountName)[0].Value

# Create storage context
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey

# Download script to local temp directory
$LocalPath = "$env:TEMP\$ScriptName"
Get-AzStorageBlobContent -Container $ContainerName -Blob $ScriptName -Destination $LocalPath -Context $StorageContext

# Execute the script
& $LocalPath
```

#### Ubuntu Server VMs

Use Azure CLI to download and execute scripts:

```bash
# Install Azure CLI if not already present
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Authenticate (you may need to use device login or service principal)
az login

# Download script using Azure CLI
az storage blob download \
  --account-name thorlabsst1eastus2 \
  --container-name scripts \
  --name ubuntu-setup.sh \
  --file /tmp/ubuntu-setup.sh \
  --auth-mode login

# Make script executable and run it
chmod +x /tmp/ubuntu-setup.sh
/tmp/ubuntu-setup.sh
```

### Alternative: Using wget/curl with SAS tokens

For scenarios where Azure CLI is not available, you can generate SAS tokens:

```bash
# Generate a SAS token for the blob (valid for 1 hour)
EXPIRY=$(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')
SAS_TOKEN=$(az storage blob generate-sas \
  --account-name thorlabsst1eastus2 \
  --container-name scripts \
  --name ubuntu-setup.sh \
  --permissions r \
  --expiry $EXPIRY \
  --account-key $STORAGE_KEY \
  -o tsv)

# Download using wget or curl
wget "https://thorlabsst1eastus2.blob.core.windows.net/scripts/ubuntu-setup.sh?$SAS_TOKEN" -O /tmp/ubuntu-setup.sh
```

### Security Considerations

- **Access Control**: The storage account allows shared key access for lab simplicity, but uses HTTPS-only transport
- **Network Security**: Default network access is allowed for ease of use in the lab environment
- **Retention**: Blob deletion retention is enabled for 7 days to recover accidentally deleted scripts
- **Secrets**: Never store sensitive data like passwords directly in scripts; use Azure Key Vault or environment variables

---

## Documenting Manual Actions

- Add all manual PowerShell or CLI commands to `history.md` in the repo root for traceability.

---

For secrets and workflow setup, see `docs/GITHUB_SECRETS_CHECKLIST.md`.
