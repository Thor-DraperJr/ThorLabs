# Azure Connection Fix

Fix Logic App connections that show "Unauthenticated" or "Error" status using Azure MCP server.

## Context
@workspace - Current ThorLabs repository
@azure - Azure resources and subscriptions

## Steps
1. List problematic connections: `#azure-connection-list`
2. Identify connection details: `#azure-connection-details`  
3. Apply REST API fix: `#azure-connection-update`
4. Verify fix: `#azure-connection-verify`

## References
- #azure-connection-management.md - Full technical details
- Microsoft.Web/connections API - 2018-07-01-preview
- Grant types: "code" (OAuth) or "client_credentials"

## Example Usage
```
@azure List all Logic App connections with Error status in resource group "SecCP-Playbooks"
```
