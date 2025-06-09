# ThorLabs Lab Environment: Azure Pipeline with Bicep

## Quick Start

Deploy the ThorLabs lab environment to your Azure subscription with one click:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FThor-DraperJr%2FThorLabs%2Fmain%2Finfra%2Fmain.bicep)

**After clicking the button:**
1. You'll be redirected to the Azure portal
2. Sign in to your Azure account if prompted
3. Select your subscription and resource group (or create a new one)
4. Provide the required parameters:
   - `adminUsername`: Username for the VM administrator
   - `adminPassword`: Secure password for the VM (will be prompted securely)
5. Review and create the deployment

**Note:** The template will deploy a Ubuntu VM with associated networking resources. For detailed manual deployment steps, parameter customization, and cost control options, see [`docs/INSTRUCTIONS.md`](docs/INSTRUCTIONS.md).

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

## Repository Structure

- [`README.md`](README.md) — High-level overview, Quick Start deploy button, and quick reference
- [`docs/INSTRUCTIONS.md`](docs/INSTRUCTIONS.md) — Step-by-step deployment and management instructions
- [`docs/GITHUB_SECRETS_CHECKLIST.md`](docs/GITHUB_SECRETS_CHECKLIST.md) — Checklist and instructions for GitHub Actions secrets
- [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) — GitHub Actions workflow for automated Azure deployment
- [`infra/`](infra/) — Bicep templates and parameter files
- [`policies/`](policies/) — Azure Policy definitions for governance and compliance
- [`history.md`](history.md) — Log of manual actions and commands

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

## Security & Best Practices

- **Never commit real secrets, passwords, or subscription IDs to the repo.** Use placeholders and store sensitive values as GitHub Actions secrets. For a detailed checklist, see [GitHub Secrets Checklist](docs/GITHUB_SECRETS_CHECKLIST.md).
- Reference secrets in your workflows using `${{ secrets.SECRET_NAME }}`.
- Update documentation and checklists as your environment evolves.

---

For detailed instructions and secrets management, see the `docs/` folder.
