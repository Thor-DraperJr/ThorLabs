# Azure Policies for ThorLabs Environment

This directory contains Azure Policy definitions for governance and compliance in the ThorLabs lab environment.

## Available Policies

### VM Auto-Shutdown Enforcement (`enforce-vm-autoshutdown-7pm-et.json`)

**Purpose:** Audits virtual machines to ensure they have the required auto-shutdown tags for cost control.

**What it does:**
- Checks that all VMs have an `AutoShutdown_Time` tag set to `19:00` (7 PM)
- Checks that all VMs have an `AutoShutdown_TimeZone` tag set to `Eastern Standard Time`
- Flags VMs as non-compliant if either tag is missing or has an incorrect value

**Effect:** `Audit` - This policy only reports compliance status; it does not prevent VM creation or modify existing VMs.

## How to Deploy a Policy

### Using Azure CLI

1. **Create the policy definition:**
   ```bash
   az policy definition create \
     --name "audit-vm-autoshutdown-7pm-et" \
     --display-name "Audit VMs for Auto-Shutdown Tags (7 PM ET)" \
     --description "Audits VMs for required auto-shutdown tags" \
     --rules policies/enforce-vm-autoshutdown-7pm-et.json \
     --mode Indexed
   ```

2. **Assign the policy to a subscription:**
   ```bash
   az policy assignment create \
     --name "audit-vm-autoshutdown-assignment" \
     --display-name "Audit VM Auto-Shutdown Tags" \
     --policy "audit-vm-autoshutdown-7pm-et" \
     --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```

3. **Assign the policy to a resource group (alternative):**
   ```bash
   az policy assignment create \
     --name "audit-vm-autoshutdown-rg" \
     --display-name "Audit VM Auto-Shutdown Tags - RG" \
     --policy "audit-vm-autoshutdown-7pm-et" \
     --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/thorlabs-rg"
   ```

### Using Azure Portal

1. Navigate to **Policy** in the Azure Portal
2. Select **Definitions** and click **+ Policy definition**
3. Set the **Definition location** to your subscription
4. Copy and paste the JSON content from `enforce-vm-autoshutdown-7pm-et.json`
5. Save the definition
6. Go to **Assignments** and create a new assignment using your policy definition

### Using Bicep (Recommended)

The Bicep template `enforce-vm-autoshutdown-7pm-et.bicep` defines and assigns the policy at subscription scope in a single deployment:

1. **Deploy using Azure CLI:**
   ```bash
   az deployment sub create \
     --location eastus2 \
     --template-file policies/enforce-vm-autoshutdown-7pm-et.bicep \
     --parameters requiredShutdownTime="19:00" \
     --parameters requiredTimeZone="Eastern Standard Time"
   ```

2. **Deploy with custom parameters:**
   ```bash
   az deployment sub create \
     --location eastus2 \
     --template-file policies/enforce-vm-autoshutdown-7pm-et.bicep \
     --parameters requiredShutdownTime="18:00" \
     --parameters requiredTimeZone="Pacific Standard Time" \
     --parameters assignmentName="audit-vm-autoshutdown-west"
   ```

3. **Deploy via GitHub Actions:**
   The policy will be automatically deployed when using the workflow in `.github/workflows/deploy.yml` (see GitHub Actions section below).

### Using GitHub Actions

The policy can be deployed automatically via the GitHub Actions workflow. The workflow is configured to deploy all `*.bicep` files in the `policies/` directory at subscription scope.

**Prerequisites:**
- Ensure your GitHub Actions secrets include `AZURE_CREDENTIALS` with subscription-level permissions
- The workflow requires `AZURE_SUBSCRIPTION_ID` to be set as a secret

**Example workflow step:**
```yaml
- name: Deploy Policies
  run: |
    for policy in policies/*.bicep; do
      if [ -f "$policy" ]; then
        echo "Deploying policy: $policy"
        az deployment sub create \
          --location eastus2 \
          --template-file "$policy"
      fi
    done
```

## Important Notes and Limitations

### What This Policy Does NOT Do

- **Does not automatically shut down VMs** - This policy only audits for the presence of tags
- **Does not create or modify tags** - VMs must be tagged manually or through automation
- **Does not prevent VM creation** - VMs can still be created without the required tags (they'll just be flagged as non-compliant)

### Enforcement of Auto-Shutdown

To actually enforce the auto-shutdown based on these tags, you need additional automation such as:

1. **Azure Automation Runbook** - A PowerShell script that runs on a schedule to check VM tags and shut down VMs accordingly
2. **Logic App** - A workflow that triggers based on time and shuts down tagged VMs
3. **Azure Functions** - A serverless function triggered by a timer that processes VM tags and performs shutdowns
4. **Third-party tools** - Azure cost management tools that can process these tags

### Example Tag Values

When creating or updating VMs, ensure they have these tags:

```json
{
  "AutoShutdown_Time": "19:00",
  "AutoShutdown_TimeZone": "Eastern Standard Time"
}
```

### Customizing the Policy

You can modify the policy parameters when assigning it:

- `requiredShutdownTime`: Change from "19:00" to a different time (24-hour format)
- `requiredTimeZone`: Change to a different time zone (use Azure-supported time zone names)

## Monitoring Compliance

After assigning the policy:

1. **Azure Portal:** Go to Policy > Compliance to view compliance status
2. **Azure CLI:** Use `az policy state list` to query compliance results
3. **Azure Resource Graph:** Query compliance data programmatically

## Cost Management Benefits

By ensuring all VMs have auto-shutdown tags:

- Reduces Azure compute costs by automatically shutting down lab VMs after hours
- Provides visibility into which VMs are configured for cost control
- Enables consistent shutdown schedules across the lab environment
- Supports the ThorLabs goal of keeping costs low when resources aren't needed

## Integration with Existing Workflows

This policy complements the existing ThorLabs infrastructure:

- Works alongside Bicep templates in the `infra/` directory
- Can be deployed via the existing GitHub Actions workflow
- Follows the same naming conventions (`thorlabs-*`)
- Integrates with the cost control strategies documented in `docs/INSTRUCTIONS.md`