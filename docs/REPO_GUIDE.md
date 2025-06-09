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

- `README.md` — High-level overview, project goals, and quick reference to the most important tasks and files.
- `docs/` — Contains detailed instructions, deployment guides, and checklists for secrets and variables.
- `infra/` — All Bicep templates and parameter files for Azure resource deployments.

---

## Key Files

- `README.md`: Start here for a summary of the project, naming conventions, and links to detailed docs.
- `docs/INSTRUCTIONS.md`: Step-by-step deployment and management instructions (moved from README for clarity).
- `docs/GITHUB_SECRETS_CHECKLIST.md`: Checklist and instructions for managing GitHub Actions secrets and variables.
- `infra/main.bicep`: Main Bicep template for deploying resources (e.g., Ubuntu VM).
- `infra/main.parameters.json`: Parameters for customizing deployments.

---

## How to Use This Repo

1. **Read the `README.md`** for a project overview and to understand the repo layout.
2. **Follow `docs/INSTRUCTIONS.md`** for step-by-step deployment and management tasks.
3. **Set up your GitHub Actions secrets** as described in `docs/GITHUB_SECRETS_CHECKLIST.md`.
4. **Customize and deploy** your lab environment using the Bicep templates in `infra/`.
5. **Document all manual commands** in a `history.md` file for traceability.

---

## Security & Best Practices

- Never commit real secrets, passwords, or subscription IDs to the repo. Use placeholders and store sensitive values as GitHub Actions secrets.
- Reference secrets in your workflows using `${{ secrets.SECRET_NAME }}`.
- Update documentation and checklists as your environment evolves.

---

For more details, see the files in the `docs/` folder.
