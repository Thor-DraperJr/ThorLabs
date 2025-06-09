# GitHub Actions: Secrets & Variables Checklist

Keep this file up to date with all the secrets and variables your workflows require. Store these in your repository's **Settings > Actions > Secrets and variables** section.

---

## Required Secrets

- `AZURE_SUBSCRIPTION_ID`  
  Your Azure Subscription ID (**do not commit your actual subscription ID to the repo;** use a placeholder or document to add it as a secret in GitHub Actions).

- `ADMIN_PASSWORD`  
  The admin password for your Ubuntu VM deployments (never commit this to source control)

- `WINDOWS_ADMIN_PASSWORD`  
  The admin password for your Windows Server VM deployments (never commit this to source control). Used for Windows Server 2022 Entra ID/MDI deployments.

- `AZURE_CREDENTIALS`  
  (If using GitHub Actions to deploy to Azure) Service principal credentials in JSON format for authentication.  
  **How to create:**
  1. In Azure Cloud Shell or your terminal, run:
     ```bash
     export SUBSCRIPTION_ID=<your-subscription-id>
     az ad sp create-for-rbac --name "thorlabs-sp-eastus2" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID --sdk-auth
     ```
  2. Copy the JSON output and add it as the `AZURE_CREDENTIALS` secret in your repo's GitHub Actions secrets.

---

## Optional/Additional Secrets

- Any other credentials or tokens needed for your workflows (e.g., storage account keys, API tokens)

---

## Usage Example in Workflow YAML

See `docs/DEPLOY_WORKFLOW.md` for a full example workflow file.

```yaml
env:
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
  WINDOWS_ADMIN_PASSWORD: ${{ secrets.WINDOWS_ADMIN_PASSWORD }}
  AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

---

> **Tip:** Update this checklist whenever you add or remove secrets from your workflows.
