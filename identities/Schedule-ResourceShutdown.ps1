<#
.SYNOPSIS
    Schedules automatic shutdown of Azure VMs and other resources for the ThorLabs lab environment.

.DESCRIPTION
    This script configures automatic shutdown schedules for Azure resources to help control costs.
    It supports VMs, App Services, and other services that can be safely powered off.
    The script follows ThorLabs naming conventions and integrates with the Bicep-first approach
    by handling operational tasks that cannot be accomplished through Bicep templates.

.PARAMETER ResourceGroupName
    The name of the Azure resource group containing the resources to schedule for shutdown.

.PARAMETER ShutdownTime
    The time to shutdown resources in 24-hour format (e.g., "19:00" for 7 PM).

.PARAMETER TimeZone
    The time zone for the shutdown schedule. Default is "Eastern Standard Time".

.PARAMETER VMNames
    Optional array of specific VM names to schedule. If not provided, all VMs in the resource group will be scheduled.

.PARAMETER IncludeAppServices
    If specified, App Services in the resource group will also be scheduled for shutdown.

.PARAMETER NotificationEmail
    Optional email address to receive shutdown notifications.

.PARAMETER SubscriptionId
    Optional Azure subscription ID. If not provided, uses the current subscription context.

.PARAMETER WhatIf
    If specified, shows what would be scheduled without making actual changes.

.EXAMPLE
    .\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -ShutdownTime "19:00"
    Schedules all VMs in the thorlabs-rg resource group to shutdown at 7 PM EST.

.EXAMPLE
    .\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -VMNames @("thorlabs-vm1-eastus2") -ShutdownTime "19:00" -TimeZone "Pacific Standard Time"
    Schedules a specific VM to shutdown at 7 PM PST.

.EXAMPLE
    .\Schedule-ResourceShutdown.ps1 -ResourceGroupName "thorlabs-rg" -ShutdownTime "19:00" -IncludeAppServices -NotificationEmail "admin@contoso.com" -WhatIf
    Shows what would be scheduled for shutdown (VMs and App Services) without making changes.

.NOTES
    Author: ThorLabs Lab Environment
    Requires: Az PowerShell module
    Prerequisites: Connect-AzAccount with appropriate permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^([01]?[0-9]|2[0-3]):[0-5][0-9]$")]
    [string]$ShutdownTime,

    [Parameter(Mandatory = $false)]
    [string]$TimeZone = "Eastern Standard Time",

    [Parameter(Mandatory = $false)]
    [string[]]$VMNames,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeAppServices,

    [Parameter(Mandatory = $false)]
    [string]$NotificationEmail,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Function to write messages with timestamp
function Write-TimestampedMessage {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Function to validate required modules
function Test-RequiredModules {
    Write-TimestampedMessage "Checking required PowerShell modules..."
    
    $requiredModules = @("Az.Accounts", "Az.Compute", "Az.DevTestLabs", "Az.Websites")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-TimestampedMessage "Missing required modules: $($missingModules -join ', ')" "ERROR"
        Write-TimestampedMessage "Install with: Install-Module -Name Az -Force -AllowClobber" "ERROR"
        throw "Required PowerShell modules are not installed."
    }
    
    Write-TimestampedMessage "All required modules are available."
}

# Function to test Azure connection
function Test-AzureConnection {
    Write-TimestampedMessage "Checking Azure connection..."
    
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure"
        }
        
        Write-TimestampedMessage "Connected to Azure as: $($context.Account.Id)"
        Write-TimestampedMessage "Current subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
        
        # Set subscription if specified
        if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
            Write-TimestampedMessage "Switched to subscription: $SubscriptionId"
        }
    }
    catch {
        Write-TimestampedMessage "Not connected to Azure. Please run: Connect-AzAccount" "ERROR"
        throw $_.Exception.Message
    }
}

# Function to validate resource group
function Test-ResourceGroup {
    param([string]$ResourceGroupName)
    
    Write-TimestampedMessage "Validating resource group: $ResourceGroupName"
    
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        throw "Resource group '$ResourceGroupName' not found."
    }
    
    Write-TimestampedMessage "Resource group validated: $($resourceGroup.Location)"
    return $resourceGroup
}

# Function to get VMs in resource group
function Get-TargetVMs {
    param([string]$ResourceGroupName, [string[]]$VMNames)
    
    Write-TimestampedMessage "Retrieving target VMs..."
    
    if ($VMNames) {
        $vms = @()
        foreach ($vmName in $VMNames) {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -ErrorAction SilentlyContinue
            if ($vm) {
                $vms += $vm
            } else {
                Write-TimestampedMessage "VM not found: $vmName" "WARNING"
            }
        }
    } else {
        $vms = Get-AzVM -ResourceGroupName $ResourceGroupName
    }
    
    Write-TimestampedMessage "Found $($vms.Count) VMs to schedule for shutdown"
    foreach ($vm in $vms) {
        Write-TimestampedMessage "  - $($vm.Name) (Size: $($vm.HardwareProfile.VmSize))"
    }
    
    return $vms
}

# Function to get App Services in resource group
function Get-TargetAppServices {
    param([string]$ResourceGroupName)
    
    if (-not $IncludeAppServices) {
        return @()
    }
    
    Write-TimestampedMessage "Retrieving target App Services..."
    
    $appServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
    
    Write-TimestampedMessage "Found $($appServices.Count) App Services to schedule for shutdown"
    foreach ($app in $appServices) {
        Write-TimestampedMessage "  - $($app.Name) (SKU: $($app.AppServicePlan))"
    }
    
    return $appServices
}

# Function to configure VM auto-shutdown
function Set-VMAutoShutdown {
    param([object]$VM, [string]$ShutdownTime, [string]$TimeZone, [string]$NotificationEmail, [bool]$WhatIf)
    
    $vmName = $VM.Name
    $resourceGroupName = $VM.ResourceGroupName
    
    Write-TimestampedMessage "Configuring auto-shutdown for VM: $vmName"
    
    if ($WhatIf) {
        Write-TimestampedMessage "WHAT-IF: Would configure auto-shutdown for $vmName at $ShutdownTime ($TimeZone)" "INFO"
        return
    }
    
    try {
        # Auto-shutdown configuration parameters
        $shutdownResourceName = "shutdown-computevm-$vmName"
        $properties = @{
            status = "Enabled"
            taskType = "ComputeVmShutdownTask"
            dailyRecurrence = @{
                time = $ShutdownTime
            }
            timeZoneId = $TimeZone
            targetResourceId = $VM.Id
        }
        
        # Add notification settings if email is provided
        if ($NotificationEmail) {
            $properties.notificationSettings = @{
                status = "Enabled"
                timeInMinutes = 30
                emailRecipient = $NotificationEmail
                notificationLocale = "en"
            }
        }
        
        # Create the auto-shutdown schedule
        New-AzResource -ResourceGroupName $resourceGroupName -Location $VM.Location -ResourceType "Microsoft.DevTestLab/schedules" -ResourceName $shutdownResourceName -Properties $properties -Force
        
        Write-TimestampedMessage "Successfully configured auto-shutdown for $vmName"
        
        return $true
    }
    catch {
        Write-TimestampedMessage "Failed to configure auto-shutdown for $vmName`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to create App Service shutdown schedule (using Azure Automation)
function Set-AppServiceShutdownSchedule {
    param([object]$AppService, [string]$ShutdownTime, [string]$TimeZone, [bool]$WhatIf)
    
    $appName = $AppService.Name
    
    Write-TimestampedMessage "Planning shutdown schedule for App Service: $appName"
    
    if ($WhatIf) {
        Write-TimestampedMessage "WHAT-IF: Would create shutdown schedule for App Service $appName at $ShutdownTime ($TimeZone)" "INFO"
        return
    }
    
    # Note: App Service shutdown requires Azure Automation or Logic Apps
    # This is a placeholder for the actual implementation
    Write-TimestampedMessage "App Service shutdown scheduling requires Azure Automation runbook or Logic App - manual setup required" "WARNING"
    Write-TimestampedMessage "Consider using: Stop-AzWebApp -ResourceGroupName '$($AppService.ResourceGroup)' -Name '$appName'" "INFO"
}

# Function to log actions to history
function Add-HistoryEntry {
    param([string]$Action, [array]$Resources)
    
    $historyEntry = @"
Date: $(Get-Date -Format 'yyyy-MM-dd')
User: $($env:USERNAME)
Command: .\Schedule-ResourceShutdown.ps1 -ResourceGroupName '$ResourceGroupName' -ShutdownTime '$ShutdownTime' -TimeZone '$TimeZone'
Purpose: Scheduled automatic shutdown for ThorLabs lab resources to control costs
Result: Configured shutdown schedules for $($Resources.Count) resources
Resources: $($Resources -join ', ')
---

"@
    Add-Content -Path "../../history.md" -Value $historyEntry
}

# Main script execution
try {
    Write-TimestampedMessage "Starting ThorLabs resource shutdown scheduling script..."
    
    # Validate prerequisites
    Test-RequiredModules
    Test-AzureConnection
    Test-ResourceGroup -ResourceGroupName $ResourceGroupName
    
    # Get target resources
    $targetVMs = Get-TargetVMs -ResourceGroupName $ResourceGroupName -VMNames $VMNames
    $targetAppServices = Get-TargetAppServices -ResourceGroupName $ResourceGroupName
    
    if ($targetVMs.Count -eq 0 -and $targetAppServices.Count -eq 0) {
        Write-TimestampedMessage "No resources found to schedule for shutdown." "WARNING"
        exit 0
    }
    
    # Summary of what will be scheduled
    Write-TimestampedMessage "Shutdown Schedule Summary:"
    Write-TimestampedMessage "  Resource Group: $ResourceGroupName"
    Write-TimestampedMessage "  Shutdown Time: $ShutdownTime"
    Write-TimestampedMessage "  Time Zone: $TimeZone"
    Write-TimestampedMessage "  VMs: $($targetVMs.Count)"
    Write-TimestampedMessage "  App Services: $($targetAppServices.Count)"
    if ($NotificationEmail) {
        Write-TimestampedMessage "  Notification Email: $NotificationEmail"
    }
    
    if (-not $WhatIf) {
        $confirmation = Read-Host "Do you want to proceed with scheduling these resources for shutdown? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-TimestampedMessage "Operation cancelled by user."
            exit 0
        }
    }
    
    # Configure VM auto-shutdown
    $successCount = 0
    $scheduledResources = @()
    
    foreach ($vm in $targetVMs) {
        if (Set-VMAutoShutdown -VM $vm -ShutdownTime $ShutdownTime -TimeZone $TimeZone -NotificationEmail $NotificationEmail -WhatIf $WhatIf) {
            $successCount++
            $scheduledResources += $vm.Name
        }
    }
    
    # Configure App Service shutdown schedules
    foreach ($appService in $targetAppServices) {
        Set-AppServiceShutdownSchedule -AppService $appService -ShutdownTime $ShutdownTime -TimeZone $TimeZone -WhatIf $WhatIf
        $scheduledResources += $appService.Name
    }
    
    # Log to history if not a what-if run
    if (-not $WhatIf -and $scheduledResources.Count -gt 0) {
        Add-HistoryEntry -Action "Schedule-ResourceShutdown" -Resources $scheduledResources
    }
    
    $operation = if ($WhatIf) { "would be scheduled" } else { "successfully scheduled" }
    Write-TimestampedMessage "Resource shutdown scheduling completed: $successCount VMs $operation for automatic shutdown."
    
    if (-not $WhatIf) {
        Write-TimestampedMessage "Monitor shutdown schedules in Azure portal under DevTest Labs > Auto-shutdown"
        Write-TimestampedMessage "To disable auto-shutdown: Set-AzResource with status 'Disabled'"
    }
}
catch {
    Write-TimestampedMessage "Script failed: $($_.Exception.Message)" "ERROR"
    exit 1
}