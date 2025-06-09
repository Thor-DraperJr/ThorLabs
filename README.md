# ThorLabs Lab Environment: Azure Pipeline with Bicep

## Quick Start

Deploy the ThorLabs lab environment to your Azure subscription with one click:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FThor-DraperJr%2FThorLabs%2Fmain%2Finfra%2Flab.bicep)

**After clicking the button:**
1. You'll be redirected to the Azure portal
2. Sign in to your Azure account if prompted
3. Select your subscription and resource group (or create a new one)
4. Provide the required parameters:
   - `adminUsername`: Username for the VM administrator
   - `adminPassword`: Secure password for the VM (will be prompted securely)
5. Review and create the deployment

**Note:** The template will deploy both Ubuntu and Windows Server VMs with shared networking resources in a single deployment. For detailed manual deployment steps, parameter customization, and cost control options, see [`docs/INSTRUCTIONS.md`](docs/INSTRUCTIONS.md).

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

```text
thorlabs-db1-eastus
thorlabs-vm2-eastus
```

---

## Repository Structure

- [`README.md`](README.md) — High-level overview, Quick Start deploy button, and quick reference
- [`docs/INSTRUCTIONS.md`](docs/INSTRUCTIONS.md) — Step-by-step deployment and management instructions
- [`docs/GITHUB_SECRETS_CHECKLIST.md`](docs/GITHUB_SECRETS_CHECKLIST.md) — Checklist and instructions for GitHub Actions secrets
- [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) — GitHub Actions workflow for automated deployment of both Ubuntu and Windows servers
- [`.github/workflows/cleanup-lab.yml`](.github/workflows/cleanup-lab.yml) — GitHub Actions workflow for manual cleanup of the lab environment
- [`.github/COPILOT_INSTRUCTIONS.md`](.github/COPILOT_INSTRUCTIONS.md) — Comprehensive guidelines for GitHub Copilot and contributors
- [`infra/`](infra/) — Unified Bicep template and parameters for lab environment (both Ubuntu and Windows VMs)
- [`bicep/`](bicep/) — Legacy Bicep templates (for reference)
- [`scripts/`](scripts/) — PowerShell scripts for server configuration
- [`policies/`](policies/) — Azure Policy definitions for governance and compliance
- [`history.md`](history.md) — Log of manual actions and commands

## Automated Deployment

The GitHub Actions workflow in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) automatically deploys the complete lab environment on every push to the `main` branch, including:

- **Ubuntu Server VM** (`thorlabs-vm1-eastus2`) - General purpose Linux workstation  
- **Windows Server 2022 VM** (`thorlabs-vm2-eastus2`) - Windows Server configuration with RDP access
- **Shared networking** - Single VNet (10.10.0.0/16), subnet (10.10.0.0/24), and NSG with SSH/RDP rules
- **Azure Policy definitions** - For governance and cost control

Both virtual machines are deployed in the same shared network infrastructure for simplified management and follow the established naming convention with auto-shutdown policies for cost control.

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

## Deploying Azure Policies

This repository includes Azure Policy definitions in the `policies/` folder to enforce governance and compliance. Policies can be deployed using:

- **Bicep templates** (recommended) - Infrastructure as Code approach with version control
- **Azure CLI** - Manual deployment using JSON definitions
- **GitHub Actions** - Automated deployment via CI/CD pipeline

**Key Benefits:**
- Audit VM auto-shutdown tags for cost control
- Ensure consistent governance across resources
- Automated compliance monitoring

For detailed policy deployment instructions, examples, and troubleshooting, see [`policies/README.md`](policies/README.md).

---

## Contributor Guidelines

This repository follows strict guidelines to ensure consistency, security, and Microsoft/Azure native approach:

- **Naming Conventions**: All Azure resources must follow the `thorlabs-{service}{number}-{region}` format
- **Technology Stack**: Use only Microsoft/Azure native tools (Bicep, PowerShell, Azure CLI, Windows Server, Ubuntu for Azure)
- **Documentation Requirements**: All significant changes must be documented in README and the `docs/` folder
- **Code Review Standards**: Pull requests must follow naming convention compliance and documentation update requirements

For comprehensive guidelines, see [GitHub Copilot Instructions](.github/COPILOT_INSTRUCTIONS.md).

---

## Security & Best Practices

- **Never commit real secrets, passwords, or subscription IDs to the repo.** Use placeholders and store sensitive values as GitHub Actions secrets. For a detailed checklist, see [GitHub Secrets Checklist](docs/GITHUB_SECRETS_CHECKLIST.md).
- Reference secrets in your workflows using `${{ secrets.SECRET_NAME }}`.
- Update documentation and checklists as your environment evolves.

---

For detailed instructions and secrets management, see the `docs/` folder.
