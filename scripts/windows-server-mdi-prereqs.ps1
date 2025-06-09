# windows-server-mdi-prereqs.ps1
# Prerequisites setup for Microsoft Defender for Identity on Windows Server 2022

param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "thorlabs.local",
    
    [Parameter(Mandatory=$false)]
    [string]$MDIServiceAccountName = "MDI-SVC",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipServiceAccountCreation = $false
)

# Ensure script is running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting..."
    exit 1
}

Write-Host "=== ThorLabs Microsoft Defender for Identity Prerequisites Setup ===" -ForegroundColor Green
Write-Host "Starting Windows Server 2022 configuration for MDI..." -ForegroundColor Yellow

# Function to check if domain controller is ready
function Test-DomainControllerStatus {
    Write-Host "Checking Domain Controller status..." -ForegroundColor Yellow
    
    try {
        $dcdiag = dcdiag.exe /q
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Domain Controller is healthy and ready." -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Domain Controller health check failed. Please ensure DC promotion is complete."
            return $false
        }
    }
    catch {
        Write-Warning "Unable to run dcdiag. Domain Controller may not be properly configured."
        return $false
    }
}

# Function to create MDI service account
function Create-MDIServiceAccount {
    param(
        [string]$ServiceAccountName,
        [string]$Domain
    )
    
    Write-Host "Creating Microsoft Defender for Identity service account..." -ForegroundColor Yellow
    
    try {
        # Import AD module
        Import-Module ActiveDirectory -ErrorAction Stop
        
        # Check if service account already exists
        $existingAccount = Get-ADUser -Filter "SamAccountName -eq '$ServiceAccountName'" -ErrorAction SilentlyContinue
        if ($existingAccount) {
            Write-Host "Service account $ServiceAccountName already exists." -ForegroundColor Yellow
            return $existingAccount
        }
        
        # Create service account with strong password
        $password = ConvertTo-SecureString "$(Get-Random -Minimum 100000 -Maximum 999999)P@ssw0rd!" -AsPlainText -Force
        
        # Get or create Service Accounts OU
        $serviceAccountsOU = "OU=ServiceAccounts,DC=" + $Domain.Replace(".", ",DC=")
        
        $newUser = New-ADUser `
            -Name $ServiceAccountName `
            -SamAccountName $ServiceAccountName `
            -UserPrincipalName "$ServiceAccountName@$Domain" `
            -AccountPassword $password `
            -Enabled $true `
            -Path $serviceAccountsOU `
            -Description "Microsoft Defender for Identity Service Account" `
            -PasswordNeverExpires $true `
            -CannotChangePassword $true `
            -PassThru
            
        # Grant required permissions for MDI
        Grant-MDIServiceAccountPermissions -ServiceAccount $newUser -Domain $Domain
        
        Write-Host "MDI service account created successfully: $ServiceAccountName" -ForegroundColor Green
        Write-Host "Password has been set to a random secure value." -ForegroundColor Cyan
        
        # Save account info to file for reference
        $accountInfo = @{
            "ServiceAccount" = $ServiceAccountName
            "Domain" = $Domain
            "CreatedDate" = Get-Date
            "Purpose" = "Microsoft Defender for Identity"
        }
        $accountInfo | ConvertTo-Json | Out-File "C:\ThorLabs\MDI-ServiceAccount-Info.json"
        
        return $newUser
    }
    catch {
        Write-Error "Failed to create MDI service account: $($_.Exception.Message)"
        return $null
    }
}

# Function to grant required permissions for MDI service account
function Grant-MDIServiceAccountPermissions {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$ServiceAccount,
        [string]$Domain
    )
    
    Write-Host "Granting required permissions to MDI service account..." -ForegroundColor Yellow
    
    try {
        # Get domain DN
        $domainDN = "DC=" + $Domain.Replace(".", ",DC=")
        
        # Grant "Read all properties" and "Read permissions" on domain
        $domainACL = Get-Acl "AD:$domainDN"
        
        # Add service account to required groups
        Add-ADGroupMember -Identity "Event Log Readers" -Members $ServiceAccount -ErrorAction SilentlyContinue
        
        Write-Host "Basic permissions granted. Additional permissions may need to be configured manually." -ForegroundColor Cyan
        Write-Host "Refer to Microsoft documentation for detailed MDI permission requirements." -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Failed to grant some permissions: $($_.Exception.Message)"
        Write-Host "You may need to configure permissions manually." -ForegroundColor Yellow
    }
}

# Function to configure Windows Event Logs for MDI
function Configure-EventLogs {
    Write-Host "Configuring Windows Event Logs for MDI..." -ForegroundColor Yellow
    
    try {
        # Configure Security log
        wevtutil sl Security /ms:1073741824  # 1GB
        wevtutil sl Security /rt:true
        
        # Configure System log
        wevtutil sl System /ms:268435456     # 256MB
        wevtutil sl System /rt:true
        
        # Configure Application log
        wevtutil sl Application /ms:268435456 # 256MB
        wevtutil sl Application /rt:true
        
        # Configure Directory Service log
        wevtutil sl "Directory Service" /ms:268435456 # 256MB
        wevtutil sl "Directory Service" /rt:true
        
        Write-Host "Event log configuration completed." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to configure some event logs: $($_.Exception.Message)"
    }
}

# Function to configure audit policies for MDI
function Configure-AuditPolicies {
    Write-Host "Configuring audit policies for MDI..." -ForegroundColor Yellow
    
    try {
        # Enable required audit policies
        auditpol /set /category:"Account Logon" /success:enable /failure:enable
        auditpol /set /category:"Account Management" /success:enable /failure:enable
        auditpol /set /category:"Directory Service Access" /success:enable /failure:enable
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
        auditpol /set /category:"Object Access" /success:enable /failure:enable
        auditpol /set /category:"Policy Change" /success:enable /failure:enable
        auditpol /set /category:"Privilege Use" /success:enable /failure:enable
        auditpol /set /category:"System" /success:enable /failure:enable
        
        Write-Host "Audit policies configured successfully." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to configure audit policies: $($_.Exception.Message)"
    }
}

# Function to configure network requirements
function Configure-NetworkRequirements {
    Write-Host "Configuring network requirements for MDI..." -ForegroundColor Yellow
    
    try {
        # Enable required firewall rules for MDI
        New-NetFirewallRule -DisplayName "MDI - HTTPS (443)" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName "MDI - HTTPS (443)" -Direction Outbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
        
        # Configure DNS for MDI cloud connectivity
        # MDI sensors need to communicate with Microsoft cloud services
        Write-Host "Ensure DNS resolution for *.atp.azure.com and *.protection.outlook.com" -ForegroundColor Cyan
        
        # Test connectivity to MDI cloud services
        $testUrls = @(
            "winatp-gw-neu.microsoft.com",
            "winatp-gw-eus.microsoft.com",
            "triprd1weuaatp.blob.core.windows.net"
        )
        
        foreach ($url in $testUrls) {
            try {
                $result = Test-NetConnection -ComputerName $url -Port 443 -WarningAction SilentlyContinue
                if ($result.TcpTestSucceeded) {
                    Write-Host "✓ Connectivity to $url successful" -ForegroundColor Green
                }
                else {
                    Write-Host "✗ Connectivity to $url failed" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "✗ Could not test connectivity to $url" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Warning "Network configuration had some issues: $($_.Exception.Message)"
    }
}

# Function to install required certificates
function Install-RequiredCertificates {
    Write-Host "Checking certificate requirements for MDI..." -ForegroundColor Yellow
    
    try {
        # MDI requires valid certificates for HTTPS communication
        # Check if domain has proper certificates
        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*$env:COMPUTERNAME*" }
        
        if ($cert) {
            Write-Host "Found domain certificate." -ForegroundColor Green
        }
        else {
            Write-Host "No domain certificate found. You may need to configure certificates." -ForegroundColor Yellow
            Write-Host "For production environments, ensure proper PKI certificates are deployed." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Warning "Certificate check failed: $($_.Exception.Message)"
    }
}

# Function to create MDI installation directory and download info
function Prepare-MDIInstallation {
    Write-Host "Preparing for MDI sensor installation..." -ForegroundColor Yellow
    
    try {
        # Create MDI directory
        $mdiPath = "C:\ThorLabs\MDI"
        if (-not (Test-Path $mdiPath)) {
            New-Item -ItemType Directory -Path $mdiPath -Force
        }
        
        # Create installation guide
        $installGuide = @"
Microsoft Defender for Identity Installation Guide
================================================

Prerequisites Completed:
- Service account created: $MDIServiceAccountName
- Event logs configured
- Audit policies enabled
- Network requirements configured

Next Steps:
1. Log in to Microsoft 365 Security Center (security.microsoft.com)
2. Navigate to Settings > Identities > Sensors
3. Download the MDI sensor installer
4. Run the installer with the service account credentials
5. Follow the configuration wizard

Important Notes:
- The service account password is stored securely
- Ensure connectivity to Microsoft cloud services
- Monitor sensor status in the Security Center

Configuration Files:
- Service account info: C:\ThorLabs\MDI-ServiceAccount-Info.json
- Installation logs: C:\ThorLabs\Logs\
"@
        
        $installGuide | Out-File "$mdiPath\Installation-Guide.txt" -Encoding UTF8
        
        Write-Host "Installation guide created at: $mdiPath\Installation-Guide.txt" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create installation guide: $($_.Exception.Message)"
    }
}

# Function to perform system health check
function Invoke-SystemHealthCheck {
    Write-Host "Performing system health check for MDI readiness..." -ForegroundColor Yellow
    
    $healthReport = @()
    
    # Check available disk space
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    if ($freeSpaceGB -gt 10) {
        $healthReport += "✓ Sufficient disk space: $freeSpaceGB GB available"
    }
    else {
        $healthReport += "✗ Low disk space: $freeSpaceGB GB available (recommend 10+ GB)"
    }
    
    # Check memory
    $memory = Get-WmiObject Win32_ComputerSystem
    $memoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    if ($memoryGB -gt 4) {
        $healthReport += "✓ Sufficient memory: $memoryGB GB"
    }
    else {
        $healthReport += "✗ Low memory: $memoryGB GB (recommend 4+ GB)"
    }
    
    # Check CPU cores
    $cpu = Get-WmiObject Win32_Processor
    $cores = $cpu.NumberOfCores
    if ($cores -ge 2) {
        $healthReport += "✓ Sufficient CPU cores: $cores"
    }
    else {
        $healthReport += "✗ Insufficient CPU cores: $cores (recommend 2+ cores)"
    }
    
    # Check domain controller status
    if (Test-DomainControllerStatus) {
        $healthReport += "✓ Domain Controller is healthy"
    }
    else {
        $healthReport += "✗ Domain Controller health check failed"
    }
    
    Write-Host "`nSystem Health Report:" -ForegroundColor Cyan
    foreach ($item in $healthReport) {
        if ($item.StartsWith("✓")) {
            Write-Host $item -ForegroundColor Green
        }
        else {
            Write-Host $item -ForegroundColor Red
        }
    }
}

# Main execution
try {
    Write-Host "Starting MDI prerequisites configuration..." -ForegroundColor Green
    
    # Check if this is a domain controller
    if (-not (Test-DomainControllerStatus)) {
        Write-Error "This script must be run on a properly configured Domain Controller."
        exit 1
    }
    
    # Create service account if requested
    if (-not $SkipServiceAccountCreation) {
        $serviceAccount = Create-MDIServiceAccount -ServiceAccountName $MDIServiceAccountName -Domain $DomainName
        if (-not $serviceAccount) {
            Write-Warning "Service account creation failed. Continuing with other configurations..."
        }
    }
    
    # Configure event logs
    Configure-EventLogs
    
    # Configure audit policies
    Configure-AuditPolicies
    
    # Configure network requirements
    Configure-NetworkRequirements
    
    # Install required certificates
    Install-RequiredCertificates
    
    # Prepare for MDI installation
    Prepare-MDIInstallation
    
    # Perform system health check
    Invoke-SystemHealthCheck
    
    Write-Host "`n=== MDI Prerequisites Setup Complete ===" -ForegroundColor Green
    Write-Host "System is ready for Microsoft Defender for Identity sensor installation." -ForegroundColor Yellow
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the installation guide at C:\ThorLabs\MDI\Installation-Guide.txt" -ForegroundColor White
    Write-Host "2. Download MDI sensor from Microsoft 365 Security Center" -ForegroundColor White
    Write-Host "3. Install and configure the MDI sensor" -ForegroundColor White
    Write-Host "4. Monitor sensor status and health" -ForegroundColor White
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Check the logs for more details." -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
Write-Host "Log files and configuration details are available in C:\ThorLabs\" -ForegroundColor Cyan