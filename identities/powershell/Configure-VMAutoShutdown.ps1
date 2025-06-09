# Configure-VMAutoShutdown.ps1
# PowerShell script to configure VM auto-shutdown at 7pm EST using Az PowerShell module
#
# Prerequisites:
# - Install-Module Az -Force -AllowClobber
# - Connect-AzAccount with appropriate permissions
#
# Usage Examples:
# .\Configure-VMAutoShutdown.ps1 -ResourceGroupName "thorlabs-rg" -VMName "thorlabs-vm1-eastus2"
# .\Configure-VMAutoShutdown.ps1 -ResourceGroupName "thorlabs-rg" -VMName "thorlabs-vm1-eastus2" -ShutdownTime "19:00" -TimeZone "Eastern Standard Time"
# .\Configure-VMAutoShutdown.ps1 -ResourceGroupName "thorlabs-rg" -VMName "thorlabs-vm1-eastus2" -Action Remove

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Resource group name containing the VM")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true, HelpMessage = "Virtual machine name")]
    [string]$VMName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Shutdown time in HH:mm format (24-hour)")]
    [ValidatePattern("^([01]?[0-9]|2[0-3]):[0-5][0-9]$")]
    [string]$ShutdownTime = "19:00",  # 7:00 PM
    
    [Parameter(Mandatory = $false, HelpMessage = "Time zone for shutdown")]
    [string]$TimeZone = "Eastern Standard Time",
    
    [Parameter(Mandatory = $false, HelpMessage = "Action to perform")]
    [ValidateSet("Configure", "Remove", "Status")]
    [string]$Action = "Configure",
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable email notifications")]
    [switch]$EnableNotifications,
    
    [Parameter(Mandatory = $false, HelpMessage = "Email address for notifications")]
    [string]$NotificationEmail,
    
    [Parameter(Mandatory = $false, HelpMessage = "Webhook URL for notifications")]
    [string]$WebhookUrl
)

# Function to check if Az module is installed and connected
function Test-AzConnection {
    try {
        # Check if the module is installed
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Write-Error "Azure PowerShell module is not installed. Please run: Install-Module Az -Force -AllowClobber"
            return $false
        }
        
        # Check if connected to Azure
        $context = Get-AzContext
        if (-not $context) {
            Write-Warning "Not connected to Azure. Please run: Connect-AzAccount"
            return $false
        }
        
        Write-Host "Connected to Azure Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error checking Azure connection: $($_.Exception.Message)"
        return $false
    }
}

# Function to validate VM exists
function Test-VMExists {
    param(
        [string]$RGName,
        [string]$VirtualMachineName
    )
    
    try {
        $vm = Get-AzVM -ResourceGroupName $RGName -Name $VirtualMachineName -ErrorAction SilentlyContinue
        return $null -ne $vm
    }
    catch {
        return $false
    }
}

# Function to configure auto-shutdown
function Set-VMAutoShutdown {
    param(
        [string]$RGName,
        [string]$VirtualMachineName,
        [string]$Time,
        [string]$TZ,
        [bool]$Notifications,
        [string]$Email,
        [string]$Webhook
    )
    
    try {
        Write-Host "Configuring auto-shutdown for VM: $VirtualMachineName" -ForegroundColor Yellow
        
        # Get the VM to obtain its resource ID
        $vm = Get-AzVM -ResourceGroupName $RGName -Name $VirtualMachineName
        $vmResourceId = $vm.Id
        
        # Prepare the auto-shutdown schedule resource name
        $autoShutdownResourceName = "shutdown-computevm-$VirtualMachineName"
        
        # Prepare notification settings if enabled
        $notificationSettings = @{}
        if ($Notifications -and ($Email -or $Webhook)) {
            $notificationSettings = @{
                status = "Enabled"
                timeInMinutes = 30  # Notify 30 minutes before shutdown
                emailRecipient = $Email
                webhookUrl = $Webhook
            }
        }
        else {
            $notificationSettings = @{
                status = "Disabled"
            }
        }
        
        # Create the auto-shutdown configuration
        $shutdownConfig = @{
            location = $vm.Location
            properties = @{
                status = "Enabled"
                taskType = "ComputeVmShutdownTask"
                dailyRecurrence = @{
                    time = $Time
                }
                timeZoneId = $TZ
                targetResourceId = $vmResourceId
                notificationSettings = $notificationSettings
            }
        }
        
        # Deploy the auto-shutdown configuration using REST API call via PowerShell
        # Note: Azure PowerShell doesn't have direct cmdlets for auto-shutdown, so we use REST API
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$RGName/providers/microsoft.devtestlab/schedules/$autoShutdownResourceName"
        
        # Convert to JSON
        $body = $shutdownConfig | ConvertTo-Json -Depth 10
        
        # Make REST API call
        $headers = @{
            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
            'Content-Type' = 'application/json'
        }
        
        $uri = "https://management.azure.com$resourceId" + "?api-version=2018-09-15"
        
        $response = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers $headers
        
        Write-Host "Auto-shutdown configured successfully!" -ForegroundColor Green
        Write-Host "VM: $VirtualMachineName" -ForegroundColor Cyan
        Write-Host "Shutdown Time: $Time ($TZ)" -ForegroundColor Cyan
        Write-Host "Status: Enabled" -ForegroundColor Cyan
        
        if ($Notifications) {
            Write-Host "Notifications: Enabled (30 minutes before shutdown)" -ForegroundColor Cyan
            if ($Email) { Write-Host "Email: $Email" -ForegroundColor Cyan }
            if ($Webhook) { Write-Host "Webhook: $Webhook" -ForegroundColor Cyan }
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to configure auto-shutdown: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorContent = $reader.ReadToEnd()
            Write-Error "API Error Details: $errorContent"
        }
        return $false
    }
}

# Function to remove auto-shutdown configuration
function Remove-VMAutoShutdown {
    param(
        [string]$RGName,
        [string]$VirtualMachineName
    )
    
    try {
        Write-Host "Removing auto-shutdown configuration for VM: $VirtualMachineName" -ForegroundColor Yellow
        
        $autoShutdownResourceName = "shutdown-computevm-$VirtualMachineName"
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$RGName/providers/microsoft.devtestlab/schedules/$autoShutdownResourceName"
        
        # Make REST API call to delete the auto-shutdown configuration
        $headers = @{
            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
        }
        
        $uri = "https://management.azure.com$resourceId" + "?api-version=2018-09-15"
        
        $response = Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
        
        Write-Host "Auto-shutdown configuration removed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Warning "Auto-shutdown configuration not found for VM: $VirtualMachineName"
            return $true
        }
        Write-Error "Failed to remove auto-shutdown configuration: $($_.Exception.Message)"
        return $false
    }
}

# Function to get auto-shutdown status
function Get-VMAutoShutdownStatus {
    param(
        [string]$RGName,
        [string]$VirtualMachineName
    )
    
    try {
        Write-Host "Checking auto-shutdown status for VM: $VirtualMachineName" -ForegroundColor Yellow
        
        $autoShutdownResourceName = "shutdown-computevm-$VirtualMachineName"
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$RGName/providers/microsoft.devtestlab/schedules/$autoShutdownResourceName"
        
        # Make REST API call to get the auto-shutdown configuration
        $headers = @{
            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
        }
        
        $uri = "https://management.azure.com$resourceId" + "?api-version=2018-09-15"
        
        $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
        
        if ($response) {
            Write-Host "`nAuto-shutdown Status:" -ForegroundColor Green
            Write-Host "VM: $VirtualMachineName" -ForegroundColor Cyan
            Write-Host "Status: $($response.properties.status)" -ForegroundColor Cyan
            Write-Host "Shutdown Time: $($response.properties.dailyRecurrence.time)" -ForegroundColor Cyan
            Write-Host "Time Zone: $($response.properties.timeZoneId)" -ForegroundColor Cyan
            Write-Host "Notifications: $($response.properties.notificationSettings.status)" -ForegroundColor Cyan
            
            if ($response.properties.notificationSettings.status -eq "Enabled") {
                Write-Host "Notification Time: $($response.properties.notificationSettings.timeInMinutes) minutes before shutdown" -ForegroundColor Cyan
                if ($response.properties.notificationSettings.emailRecipient) {
                    Write-Host "Email: $($response.properties.notificationSettings.emailRecipient)" -ForegroundColor Cyan
                }
            }
        }
        
        return $response
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Warning "No auto-shutdown configuration found for VM: $VirtualMachineName"
            return $null
        }
        Write-Error "Failed to get auto-shutdown status: $($_.Exception.Message)"
        return $null
    }
}

# Main script execution
try {
    Write-Host "VM Auto-Shutdown Configuration Script" -ForegroundColor Magenta
    Write-Host "=====================================" -ForegroundColor Magenta
    
    # Check Azure connection
    if (-not (Test-AzConnection)) {
        exit 1
    }
    
    # Validate VM exists
    Write-Host "Validating VM exists..." -ForegroundColor Yellow
    if (-not (Test-VMExists -RGName $ResourceGroupName -VirtualMachineName $VMName)) {
        Write-Error "VM '$VMName' not found in resource group '$ResourceGroupName'"
        exit 1
    }
    
    # Execute the requested action
    switch ($Action) {
        "Configure" {
            Write-Host "`nConfiguring auto-shutdown..." -ForegroundColor Yellow
            $success = Set-VMAutoShutdown -RGName $ResourceGroupName -VirtualMachineName $VMName -Time $ShutdownTime -TZ $TimeZone -Notifications $EnableNotifications.IsPresent -Email $NotificationEmail -Webhook $WebhookUrl
            if (-not $success) {
                exit 1
            }
        }
        "Remove" {
            Write-Host "`nRemoving auto-shutdown configuration..." -ForegroundColor Yellow
            $success = Remove-VMAutoShutdown -RGName $ResourceGroupName -VirtualMachineName $VMName
            if (-not $success) {
                exit 1
            }
        }
        "Status" {
            Write-Host "`nChecking auto-shutdown status..." -ForegroundColor Yellow
            Get-VMAutoShutdownStatus -RGName $ResourceGroupName -VirtualMachineName $VMName
        }
    }
    
    Write-Host "`nScript completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

# Additional helpful information
Write-Host "`nAdditional Information:" -ForegroundColor Cyan
Write-Host "- Auto-shutdown schedules run daily at the specified time" -ForegroundColor Gray
Write-Host "- VMs in 'Stopped (deallocated)' state will not incur compute charges" -ForegroundColor Gray
Write-Host "- You can manually start the VM anytime using: Start-AzVM -ResourceGroupName '$ResourceGroupName' -Name '$VMName'" -ForegroundColor Gray
Write-Host "- To permanently disable auto-shutdown, use the -Action Remove parameter" -ForegroundColor Gray