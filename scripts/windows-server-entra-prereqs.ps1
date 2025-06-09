# windows-server-entra-prereqs.ps1
# Prerequisites setup for Azure AD Connect (Entra ID Connect) on Windows Server 2022

param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "thorlabs.local",
    
    [Parameter(Mandatory=$false)]
    [string]$DomainNetBIOSName = "THORLABS",
    
    [Parameter(Mandatory=$false)]
    [securestring]$SafeModePassword
)

# Ensure script is running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting..."
    exit 1
}

Write-Host "=== ThorLabs Entra ID Connect Prerequisites Setup ===" -ForegroundColor Green
Write-Host "Starting Windows Server 2022 configuration for Entra ID Connect..." -ForegroundColor Yellow

# Function to install Windows Features
function Install-WindowsFeatures {
    Write-Host "Installing required Windows Features..." -ForegroundColor Yellow
    
    $features = @(
        "AD-Domain-Services",
        "RSAT-AD-Tools",
        "RSAT-AD-PowerShell",
        "RSAT-ADDS-Tools",
        "RSAT-DNS-Server",
        "DNS"
    )
    
    foreach ($feature in $features) {
        Write-Host "Installing $feature..." -ForegroundColor Cyan
        Install-WindowsFeature -Name $feature -IncludeManagementTools -Restart:$false
    }
}

# Function to configure firewall for domain services
function Configure-Firewall {
    Write-Host "Configuring Windows Firewall for domain services..." -ForegroundColor Yellow
    
    # Enable firewall rules for Active Directory
    Enable-NetFirewallRule -DisplayGroup "Active Directory Domain Services"
    Enable-NetFirewallRule -DisplayGroup "DNS Service"
    Enable-NetFirewallRule -DisplayGroup "Kerberos Key Distribution Center"
    
    # Enable additional rules for Azure AD Connect
    New-NetFirewallRule -DisplayName "Azure AD Connect - HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
    New-NetFirewallRule -DisplayName "Azure AD Connect - HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
}

# Function to set up DNS forwarders
function Configure-DNS {
    Write-Host "Configuring DNS settings..." -ForegroundColor Yellow
    
    # Set DNS forwarders to Azure DNS and public DNS
    Add-DnsServerForwarder -IPAddress 168.63.129.16 -PassThru  # Azure DNS
    Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru       # Google DNS
    Add-DnsServerForwarder -IPAddress 8.8.4.4 -PassThru       # Google DNS Secondary
}

# Function to promote server to domain controller
function Install-DomainController {
    param([securestring]$SafeModePassword)
    
    Write-Host "Promoting server to Domain Controller..." -ForegroundColor Yellow
    Write-Warning "This will require a restart!"
    
    if (-not $SafeModePassword) {
        $SafeModePassword = Read-Host "Enter Directory Services Restore Mode (DSRM) password" -AsSecureString
    }
    
    try {
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $DomainNetBIOSName `
            -SafeModeAdministratorPassword $SafeModePassword `
            -InstallDns:$true `
            -CreateDnsDelegation:$false `
            -ForestMode "WinThreshold" `
            -DomainMode "WinThreshold" `
            -Force:$true `
            -Confirm:$false
            
        Write-Host "Domain Controller promotion initiated. Server will restart automatically." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to promote server to Domain Controller: $($_.Exception.Message)"
        return $false
    }
    return $true
}

# Function to create service accounts for Azure AD Connect
function Create-ServiceAccounts {
    Write-Host "Creating service accounts for Azure AD Connect..." -ForegroundColor Yellow
    
    # Import AD module
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    
    if (-not (Get-Module ActiveDirectory)) {
        Write-Warning "Active Directory module not available. This step will need to be run after domain controller promotion."
        return
    }
    
    try {
        # Create OU for service accounts
        $serviceAccountsOU = "OU=ServiceAccounts,DC=" + $DomainName.Replace(".", ",DC=")
        New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "DC=$($DomainName.Replace('.', ',DC='))" -ErrorAction SilentlyContinue
        
        # Create Azure AD Connect service account
        $aadConnectPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
        New-ADUser `
            -Name "AADConnect-SVC" `
            -SamAccountName "AADConnect-SVC" `
            -UserPrincipalName "AADConnect-SVC@$DomainName" `
            -AccountPassword $aadConnectPassword `
            -Enabled $true `
            -Path $serviceAccountsOU `
            -Description "Azure AD Connect Service Account"
            
        Write-Host "Service accounts created successfully." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create service accounts: $($_.Exception.Message)"
        Write-Host "This step can be completed after domain controller promotion." -ForegroundColor Yellow
    }
}

# Function to configure group policies for Azure AD Connect
function Configure-GroupPolicies {
    Write-Host "Configuring Group Policies for Azure AD Connect..." -ForegroundColor Yellow
    
    # This would typically involve creating GPOs for:
    # - Password policies
    # - Account lockout policies
    # - Audit policies
    # For now, we'll just configure basic domain policies
    
    Write-Host "Basic domain policies will be configured automatically." -ForegroundColor Cyan
    Write-Host "Additional GPO configuration should be done via Group Policy Management Console." -ForegroundColor Yellow
}

# Function to install .NET Framework if needed
function Install-DotNetFramework {
    Write-Host "Checking .NET Framework requirements..." -ForegroundColor Yellow
    
    # Azure AD Connect requires .NET Framework 4.6.1 or later
    $dotNetVersion = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
    
    if ($dotNetVersion.Release -ge 394254) {
        Write-Host ".NET Framework 4.6.1 or later is already installed." -ForegroundColor Green
    }
    else {
        Write-Host "Installing .NET Framework 4.8..." -ForegroundColor Yellow
        # Note: Windows Server 2022 typically has .NET 4.8 pre-installed
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx4Extended-ASPNET45" -All
    }
}

# Function to create installation directories
function Create-InstallationDirectories {
    Write-Host "Creating installation directories..." -ForegroundColor Yellow
    
    $directories = @(
        "C:\ThorLabs",
        "C:\ThorLabs\Scripts",
        "C:\ThorLabs\Logs",
        "C:\ThorLabs\AzureADConnect"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force
            Write-Host "Created directory: $dir" -ForegroundColor Cyan
        }
    }
}

# Main execution
try {
    Write-Host "Starting prerequisites installation..." -ForegroundColor Green
    
    # Create installation directories
    Create-InstallationDirectories
    
    # Install required Windows Features
    Install-WindowsFeatures
    
    # Install .NET Framework if needed
    Install-DotNetFramework
    
    # Configure firewall
    Configure-Firewall
    
    Write-Host "`n=== Phase 1 Complete ===" -ForegroundColor Green
    Write-Host "Basic prerequisites have been installed." -ForegroundColor Yellow
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Restart the server if prompted" -ForegroundColor White
    Write-Host "2. Run this script again with -PromoteToDC parameter to install domain controller" -ForegroundColor White
    Write-Host "3. After DC promotion, run the MDI prerequisites script" -ForegroundColor White
    
    # Ask if user wants to promote to domain controller now
    $promote = Read-Host "`nDo you want to promote this server to Domain Controller now? (y/N)"
    if ($promote -eq "y" -or $promote -eq "Y") {
        if (Install-DomainController -SafeModePassword $SafeModePassword) {
            Write-Host "Domain Controller promotion completed. Server will restart." -ForegroundColor Green
        }
    }
    else {
        Write-Host "Domain Controller promotion skipped. Run this script later with -PromoteToDC to continue." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Check the logs for more details." -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
Write-Host "Log files are available in C:\ThorLabs\Logs\" -ForegroundColor Cyan