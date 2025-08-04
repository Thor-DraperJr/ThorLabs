# GitHub Actions: Secrets & Variables Checklist

Keep this file up to date with all the secrets and variables your workflows require. Store these in your repository's **Settings > Actions > Secrets and variables** section.

---

## Required Secrets

- `AZURE_SUBSCRIPTION_ID`  
  Your Azure Subscription ID (**do not commit your actual subscription ID to the repo;** use a placeholder or document to add it as a secret in GitHub Actions).

- `ADMIN_PASSWORD`  
  The admin password for your VM deployments (never commit this to source control). Used for both Ubuntu and Windows Server VMs.

- `AZURE_CREDENTIALS`  
  (If using GitHub Actions to deploy to Azure) Service principal credentials in JSON format for authentication.  
  **How to create:**
  1. In Azure Cloud Shell or your terminal, run:
     ```bash
     export SUBSCRIPTION_ID=<your-subscription-id>
     az ad sp create-for-rbac --name "thorlabs-sp-eastus2" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID --sdk-auth
     ```
  2. Copy the JSON output and add it as the `AZURE_CREDENTIALS` secret in your repo's GitHub Actions secrets.

## Optional Secrets (For Azure AD Authentication)

- `AZURE_AD_ADMIN_UPN`  
  Your Azure AD user principal name (email) for passwordless authentication. Example: `user@contoso.com`
  **How to get:** Run `az account show --query user.name --output tsv` or use `./scripts/get-azure-identity.sh`

- `AZURE_AD_ADMIN_OBJECT_ID`  
  Your Azure AD user object ID for passwordless authentication.
  **How to get:** Run `az ad signed-in-user show --query id --output tsv` or use `./scripts/get-azure-identity.sh`

> **Note:** If Azure AD secrets are not configured, workflows will fall back to SQL authentication mode.

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
  AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
  # Optional: For Azure AD authentication
  AZURE_AD_ADMIN_UPN: ${{ secrets.AZURE_AD_ADMIN_UPN }}
  AZURE_AD_ADMIN_OBJECT_ID: ${{ secrets.AZURE_AD_ADMIN_OBJECT_ID }}
```

---

> **Tip:** Update this checklist whenever you add or remove secrets from your workflows.
