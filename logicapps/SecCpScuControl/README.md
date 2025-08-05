# Security Copilot Logic Apps

Logic Apps for Security Copilot automation in ThorLabs lab.

## Deploy

```bash
# Deploy Logic App
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file SecCPDelpoyUpdate.json

# Delete resources  
az deployment group create \
  --resource-group thorlabs-rg \
  --template-file SecCPDelpoyDelete.json
```

## Templates

- `SecCPDelpoyUpdate.json` - Creates Security Copilot resources
- `SecCPDelpoyDelete.json` - Removes Security Copilot resources