# GitHub Actions Workflow: Deploy Bicep Template

This workflow will deploy your Azure resources using the Bicep template in `infra/main.bicep` whenever you push to the `main` branch.

---

## Prerequisites
- Ensure you have set the following secrets in your repository:
  - `AZURE_CREDENTIALS`
  - `AZURE_SUBSCRIPTION_ID`
  - `ADMIN_PASSWORD`

---

## Workflow File Example
Save this as `.github/workflows/deploy.yml` in your repository.

```yaml
name: Deploy Azure Lab Environment

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ADMIN_PASSWORD: ${{ secrets.ADMIN_PASSWORD }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Bicep Template
        run: |
          az deployment group create \
            --resource-group thorlabs-rg \
            --template-file infra/main.bicep \
            --parameters adminPassword="$ADMIN_PASSWORD" \
            --parameters @infra/main.parameters.json
```

---

- The workflow will run on every push to `main`.
- It uses the secrets you set up for authentication and sensitive parameters.
- You can monitor the workflow in the GitHub Actions tab after you commit and push this file.
