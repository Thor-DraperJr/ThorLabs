# Azure Logic Apps Connection Management

## 🔧 Proven Capability: Fix Logic App Connections via Azure MCP Server

**Context**: Successfully resolved "Unauthenticated" Logic App connections programmatically using Azure MCP server REST API calls (August 2025).

## ✅ Working Solution

### Problem: Logic App Connections Show "Error" Status
- **Symptoms**: `overallStatus: "Error"`, `status: "Unauthenticated"`
- **Cause**: Connection authentication has expired or failed
- **Common Connections**: Microsoft Sentinel, Security Copilot, ARM connections

### Solution: Update Connection via REST API

```bash
# Step 1: Identify problematic connections
az resource list --resource-type "Microsoft.Web/connections" --query "[].{Name:name, ResourceGroup:resourceGroup, Status:properties.overallStatus}" --output table

# Step 2: Fix connection using REST API PUT request
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Web/connections/{connection-name}?api-version=2018-07-01-preview" \
  --body '{
    "location": "eastus2",
    "properties": {
      "api": {
        "id": "/subscriptions/{subscription-id}/providers/Microsoft.Web/locations/{location}/managedApis/{api-name}"
      },
      "displayName": "{connection-display-name}",
      "parameterValueType": "Alternative",
      "alternativeParameterValues": {
        "token:TenantId": "{tenant-id}",
        "token:grantType": "code"
      }
    }
  }'

# Step 3: Verify connection is fixed
az resource show --resource-group "{resource-group}" --name "{connection-name}" --resource-type "Microsoft.Web/connections" --query "{Name:name, Status:properties.overallStatus, State:properties.connectionState}" --output json
```

### Real Example (August 2025 Success):

```bash
# Fixed Microsoft Sentinel connection
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/e440a65b-7418-4865-9821-88e411ffdd5b/resourceGroups/SecCP-Playbooks/providers/Microsoft.Web/connections/MicrosoftSentinel-SecCP-Sentinelinvestigation-DynamicSev?api-version=2018-07-01-preview" \
  --body '{
    "location": "eastus2",
    "properties": {
      "api": {
        "id": "/subscriptions/e440a65b-7418-4865-9821-88e411ffdd5b/providers/Microsoft.Web/locations/eastus2/managedApis/azuresentinel"
      },
      "displayName": "MicrosoftSentinel-SecCP-Sentinelinvestigation-DynamicSev",
      "parameterValueType": "Alternative",
      "alternativeParameterValues": {
        "token:TenantId": "8dcfbccb-ddfa-4ecb-8a53-9ace2c7a7c40",
        "token:grantType": "code"
      }
    }
  }'

# Result: overallStatus changed from "Error" to "Ready"
```

## 🎯 Key Technical Details

### Grant Types Supported:
- ✅ **`code`**: OAuth authorization flow (recommended for user connections)
- ✅ **`client_credentials`**: Service principal authentication
- ❌ **`managed_identity`**: Not supported by Logic Apps connectors

### Common API Names:
- **Microsoft Sentinel**: `azuresentinel`
- **Security Copilot**: `securitycopilot`
- **ARM (Azure Resource Manager)**: `arm`
- **Office 365**: `office365`

### Required Fields:
- **location**: Must match resource location (e.g., "eastus2")
- **api.id**: Full resource ID of the managed API
- **parameterValueType**: Use "Alternative" for custom authentication
- **token:TenantId**: Your Azure AD tenant ID
- **token:grantType**: Authentication method ("code" or "client_credentials")

## 🚫 What Doesn't Work

### Failed Approaches:
- ❌ **Portal-only solutions**: "Just use the portal" (not automatable)
- ❌ **Managed identity grant type**: Logic Apps connectors don't support it
- ❌ **Missing location field**: API requires location property
- ❌ **Wrong API version**: Use `2018-07-01-preview` for best compatibility

## 🔄 Automation Workflow

```bash
# 1. List all problematic connections
az resource list --resource-type "Microsoft.Web/connections" --query "[?properties.overallStatus=='Error'].{Name:name, ResourceGroup:resourceGroup, Location:location}"

# 2. Get tenant ID
TENANT_ID=$(az account show --query tenantId --output tsv)

# 3. Fix each connection (customize API name and connection details)
for CONNECTION in $(az resource list --resource-type "Microsoft.Web/connections" --query "[?properties.overallStatus=='Error'].name" --output tsv); do
  # Update connection logic here
done
```

## 💡 Best Practices

1. **Always verify tenant ID**: Use `az account show --query tenantId --output tsv`
2. **Use correct API version**: `2018-07-01-preview` is most reliable
3. **Include location**: Required field, must match resource location
4. **Prefer OAuth (`code`)**: More reliable than client credentials for user scenarios
5. **Test after update**: Verify `overallStatus` changes to "Ready"

## 🎉 Success Indicators

**Before Fix:**
```json
{
  "overallStatus": "Error",
  "statuses": [{"error": {"code": "Unauthenticated"}, "status": "Error"}]
}
```

**After Fix:**
```json
{
  "overallStatus": "Ready", 
  "statuses": [{"status": "Ready"}],
  "connectionState": "Enabled"
}
```

---

**Note**: This technique was validated in ThorLabs environment (August 2025) and should be the go-to method for fixing Logic App connection authentication issues programmatically.
