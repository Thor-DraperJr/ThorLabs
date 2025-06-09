# Manage-EntraUsers.ps1
# PowerShell script for basic Azure Entra (Azure AD) user management using Microsoft Graph PowerShell module
#
# Prerequisites:
# - Install-Module Microsoft.Graph -Force -AllowClobber
# - Connect-MgGraph with appropriate permissions
#
# Usage Examples:
# .\Manage-EntraUsers.ps1 -Action Create -UserPrincipalName "john.doe@yourdomain.com" -DisplayName "John Doe" -MailNickname "john.doe"
# .\Manage-EntraUsers.ps1 -Action List
# .\Manage-EntraUsers.ps1 -Action Delete -UserPrincipalName "john.doe@yourdomain.com"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "List", "Delete", "Get")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [string]$DisplayName,
    
    [Parameter(Mandatory = $false)]
    [string]$MailNickname,
    
    [Parameter(Mandatory = $false)]
    [string]$Password,
    
    [Parameter(Mandatory = $false)]
    [string]$Department,
    
    [Parameter(Mandatory = $false)]
    [string]$JobTitle
)

# Function to check if Microsoft Graph module is installed and connected
function Test-GraphConnection {
    try {
        # Check if the module is installed
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
            Write-Error "Microsoft Graph PowerShell module is not installed. Please run: Install-Module Microsoft.Graph -Force -AllowClobber"
            return $false
        }
        
        # Check if connected to Graph
        $context = Get-MgContext
        if (-not $context) {
            Write-Warning "Not connected to Microsoft Graph. Please run: Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'"
            return $false
        }
        
        Write-Host "Connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error checking Graph connection: $($_.Exception.Message)"
        return $false
    }
}

# Function to create a new user
function New-EntraUser {
    param(
        [string]$UPN,
        [string]$Name,
        [string]$Nickname,
        [string]$UserPassword,
        [string]$Dept,
        [string]$Title
    )
    
    try {
        # Generate a random password if not provided
        if (-not $UserPassword) {
            $UserPassword = -join ((33..126) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
        }
        
        $passwordProfile = @{
            Password = $UserPassword
            ForceChangePasswordNextSignIn = $true
        }
        
        $userParams = @{
            UserPrincipalName = $UPN
            DisplayName = $Name
            MailNickname = $Nickname
            PasswordProfile = $passwordProfile
            AccountEnabled = $true
            UsageLocation = "US"  # Required for license assignment
        }
        
        # Add optional parameters if provided
        if ($Dept) { $userParams.Department = $Dept }
        if ($Title) { $userParams.JobTitle = $Title }
        
        $newUser = New-MgUser @userParams
        
        Write-Host "User created successfully!" -ForegroundColor Green
        Write-Host "User Principal Name: $($newUser.UserPrincipalName)" -ForegroundColor Cyan
        Write-Host "Display Name: $($newUser.DisplayName)" -ForegroundColor Cyan
        Write-Host "Object ID: $($newUser.Id)" -ForegroundColor Cyan
        Write-Host "Temporary Password: $UserPassword" -ForegroundColor Yellow
        Write-Warning "Please save the temporary password securely. The user will be required to change it on first login."
        
        return $newUser
    }
    catch {
        Write-Error "Failed to create user: $($_.Exception.Message)"
        return $null
    }
}

# Function to list users
function Get-EntraUsers {
    try {
        Write-Host "Retrieving Azure Entra users..." -ForegroundColor Yellow
        
        # Get users with select properties for better performance
        $users = Get-MgUser -All -Property Id,UserPrincipalName,DisplayName,Mail,Department,JobTitle,AccountEnabled,CreatedDateTime | 
                 Sort-Object DisplayName
        
        if ($users) {
            Write-Host "`nFound $($users.Count) users:" -ForegroundColor Green
            $users | Format-Table -Property DisplayName, UserPrincipalName, Department, JobTitle, AccountEnabled, CreatedDateTime -AutoSize
        }
        else {
            Write-Warning "No users found."
        }
        
        return $users
    }
    catch {
        Write-Error "Failed to retrieve users: $($_.Exception.Message)"
        return $null
    }
}

# Function to get a specific user
function Get-EntraUser {
    param([string]$UPN)
    
    try {
        Write-Host "Retrieving user: $UPN" -ForegroundColor Yellow
        
        $user = Get-MgUser -UserId $UPN -Property Id,UserPrincipalName,DisplayName,Mail,Department,JobTitle,AccountEnabled,CreatedDateTime,LastSignInDateTime
        
        if ($user) {
            Write-Host "`nUser Details:" -ForegroundColor Green
            $user | Format-List -Property DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled, CreatedDateTime, LastSignInDateTime
        }
        else {
            Write-Warning "User not found: $UPN"
        }
        
        return $user
    }
    catch {
        Write-Error "Failed to retrieve user: $($_.Exception.Message)"
        return $null
    }
}

# Function to delete a user
function Remove-EntraUser {
    param([string]$UPN)
    
    try {
        # First, get the user to confirm it exists
        $user = Get-MgUser -UserId $UPN -Property DisplayName, UserPrincipalName
        
        if (-not $user) {
            Write-Warning "User not found: $UPN"
            return $false
        }
        
        # Confirm deletion
        $confirmation = Read-Host "Are you sure you want to delete user '$($user.DisplayName)' ($($user.UserPrincipalName))? (y/N)"
        
        if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
            Remove-MgUser -UserId $UPN
            Write-Host "User '$($user.DisplayName)' has been deleted successfully." -ForegroundColor Green
            Write-Warning "Note: The user has been moved to the recycle bin and can be restored within 30 days."
            return $true
        }
        else {
            Write-Host "User deletion cancelled." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Error "Failed to delete user: $($_.Exception.Message)"
        return $false
    }
}

# Main script execution
try {
    Write-Host "Azure Entra User Management Script" -ForegroundColor Magenta
    Write-Host "===================================" -ForegroundColor Magenta
    
    # Check Graph connection
    if (-not (Test-GraphConnection)) {
        exit 1
    }
    
    # Execute the requested action
    switch ($Action) {
        "Create" {
            if (-not $UserPrincipalName -or -not $DisplayName -or -not $MailNickname) {
                Write-Error "For Create action, UserPrincipalName, DisplayName, and MailNickname are required."
                exit 1
            }
            New-EntraUser -UPN $UserPrincipalName -Name $DisplayName -Nickname $MailNickname -UserPassword $Password -Dept $Department -Title $JobTitle
        }
        "List" {
            Get-EntraUsers
        }
        "Get" {
            if (-not $UserPrincipalName) {
                Write-Error "For Get action, UserPrincipalName is required."
                exit 1
            }
            Get-EntraUser -UPN $UserPrincipalName
        }
        "Delete" {
            if (-not $UserPrincipalName) {
                Write-Error "For Delete action, UserPrincipalName is required."
                exit 1
            }
            Remove-EntraUser -UPN $UserPrincipalName
        }
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}