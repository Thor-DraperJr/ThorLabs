# ThorLabs Lab Environment: Repository Guide

This document explains the structure and purpose of this repository, and how to navigate and use its contents for managing your Azure lab environment with Bicep and GitHub Actions.

---

## Purpose

This repo is designed to help you automate, document, and control your Azure resources for a lab environment using Infrastructure as Code (IaC) with Bicep templates. It emphasizes:
- Simplicity and clarity for first-time Bicep users
- Secure handling of secrets and credentials
- Cost control by turning off resources when not in use
- Repeatable, version-controlled deployments

---

## Repository Structure

- `README.md` — High-level overview, project goals, naming conventions, and quick reference
- `docs/` — Contains detailed instructions, deployment guides, and checklists for secrets and variables
- `infra/` — Unified Bicep template and parameter files for complete lab environment (Ubuntu + Windows VMs)
- `bicep/` — Legacy Bicep templates (for reference)
- `scripts/` — PowerShell scripts for server configuration and management
- `policies/` — Azure Policy definitions for governance and compliance
- `.github/` — GitHub Actions workflows and contributor guidelines

---

## Key Files

- `README.md`: Start here for project overview, naming conventions, and automated deployment information
- `docs/INSTRUCTIONS.md`: Step-by-step deployment and management instructions
- `docs/GITHUB_SECRETS_CHECKLIST.md`: Checklist and instructions for managing GitHub Actions secrets
- `docs/DEPLOY_WORKFLOW.md`: Detailed documentation of the automated deployment workflow
- `docs/MONITOR_WORKFLOW.md`: Documentation for automated deployment monitoring and failure detection
- `.github/COPILOT_INSTRUCTIONS.md`: Comprehensive guidelines for GitHub Copilot and contributors
- `.github/workflows/deploy.yml`: Automated deployment workflow for both Ubuntu and Windows servers
- `.github/workflows/monitor.yml`: Automated monitoring workflow for deployment failure detection
- `.github/workflows/cleanup-lab.yml`: Manual cleanup workflow for lab environment
- `infra/lab.bicep`: Unified Bicep template for complete lab environment (Ubuntu + Windows VMs)
- `bicep/windows-server-base.bicep`: Legacy Bicep template (for reference)
- `scripts/windows-server-*.ps1`: PowerShell scripts for Windows server configuration

---

## How to Use This Repo

### Automated Deployment (Recommended)
1. **Set up GitHub Actions secrets** as described in `docs/GITHUB_SECRETS_CHECKLIST.md`
2. **Push to main branch** - The complete lab environment (Ubuntu + Windows servers) deploys automatically
3. **Monitor deployment** in the GitHub Actions tab
4. **Configure servers** using the PowerShell scripts in `scripts/` folder after deployment

### Manual Deployment
1. **Read the `README.md`** for a project overview and to understand the repo layout
2. **Follow `docs/INSTRUCTIONS.md`** for step-by-step deployment and management tasks
3. **Customize templates** using the Bicep files in `infra/` and `bicep/` folders
4. **Document all manual commands** in `history.md` file for traceability

### Contributing
1. **Review contributor guidelines** in `.github/COPILOT_INSTRUCTIONS.md`
2. **Follow naming conventions** (`thorlabs-{service}{number}-{region}`)
3. **Use Microsoft/Azure native tools** (Bicep, PowerShell, Azure CLI)
4. **Update documentation** for all significant changes

---

## Security & Best Practices

- Never commit real secrets, passwords, or subscription IDs to the repo. Use placeholders and store sensitive values as GitHub Actions secrets.
- Reference secrets in your workflows using `${{ secrets.SECRET_NAME }}`.
- Update documentation and checklists as your environment evolves.

---

For more details, see the files in the `docs/` folder.
