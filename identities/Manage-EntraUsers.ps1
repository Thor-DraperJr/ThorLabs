<#
.SYNOPSIS
    Manages Azure AD (Entra ID) users for the ThorLabs lab environment.

.DESCRIPTION
    This script provides functions to create, list, and delete Azure AD users.
    It follows the ThorLabs repository conventions and integrates with the Bicep-first
    Infrastructure as Code approach by handling user management tasks that cannot
    be accomplished through Bicep templates.

.PARAMETER Action
    Specifies the action to perform. Valid values: List, Create, Delete

.PARAMETER UserPrincipalName
    The User Principal Name (UPN) for the user (e.g., john.doe@yourdomain.com).
    Required for Create and Delete actions.

.PARAMETER DisplayName
    The display name for the user. Required for Create action.

.PARAMETER Password
    The initial password for the user. Required for Create action.
    Should meet your organization's password complexity requirements.

.PARAMETER MailNickname
    The mail nickname for the user. If not specified, it will be derived from the UPN.

.PARAMETER ForcePasswordChange
    If specified, the user will be required to change their password on first sign-in.
    Default is $true for new users.

.EXAMPLE
    .\Manage-EntraUsers.ps1 -Action List
    Lists all users in the Azure AD tenant.

.EXAMPLE
    .\Manage-EntraUsers.ps1 -Action Create -UserPrincipalName "john.doe@contoso.com" -DisplayName "John Doe" -Password "TempPassword123!"
    Creates a new user with the specified details.

.EXAMPLE
    .\Manage-EntraUsers.ps1 -Action Delete -UserPrincipalName "john.doe@contoso.com"
    Deletes the specified user from Azure AD.

.NOTES
    Author: ThorLabs Lab Environment
    Requires: Microsoft.Graph PowerShell module
    Prerequisites: Connect-MgGraph with appropriate scopes
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("List", "Create", "Delete")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false)]
    [string]$DisplayName,

    [Parameter(Mandatory = $false)]
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [string]$MailNickname,

    [Parameter(Mandatory = $false)]
    [bool]$ForcePasswordChange = $true
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
    
    $requiredModules = @("Microsoft.Graph.Users")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-TimestampedMessage "Missing required modules: $($missingModules -join ', ')" "ERROR"
        Write-TimestampedMessage "Install with: Install-Module -Name Microsoft.Graph -Force -AllowClobber" "ERROR"
        throw "Required PowerShell modules are not installed."
    }
    
    Write-TimestampedMessage "All required modules are available."
}

# Function to test Graph connection
function Test-GraphConnection {
    Write-TimestampedMessage "Checking Microsoft Graph connection..."
    
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph"
        }
        
        Write-TimestampedMessage "Connected to Microsoft Graph as: $($context.Account)"
        
        # Check if we have the required scopes
        $requiredScopes = @("User.ReadWrite.All", "Directory.ReadWrite.All")
        $currentScopes = $context.Scopes
        
        foreach ($scope in $requiredScopes) {
            if ($scope -notin $currentScopes) {
                Write-TimestampedMessage "Missing required scope: $scope" "WARNING"
                Write-TimestampedMessage "Connect with: Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Directory.ReadWrite.All'" "WARNING"
            }
        }
    }
    catch {
        Write-TimestampedMessage "Not connected to Microsoft Graph. Please run: Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Directory.ReadWrite.All'" "ERROR"
        throw $_.Exception.Message
    }
}

# Function to list users
function Get-EntraUsers {
    Write-TimestampedMessage "Retrieving Azure AD users..."
    
    try {
        $users = Get-MgUser -All | Select-Object Id, UserPrincipalName, DisplayName, AccountEnabled, CreatedDateTime | Sort-Object DisplayName
        
        Write-TimestampedMessage "Found $($users.Count) users:"
        $users | Format-Table -AutoSize
        
        return $users
    }
    catch {
        Write-TimestampedMessage "Failed to retrieve users: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Function to create a user
function New-EntraUser {
    param(
        [string]$UserPrincipalName,
        [string]$DisplayName,
        [string]$Password,
        [string]$MailNickname,
        [bool]$ForcePasswordChange
    )
    
    Write-TimestampedMessage "Creating new Azure AD user: $UserPrincipalName"
    
    # Derive mail nickname if not provided
    if (-not $MailNickname) {
        $MailNickname = $UserPrincipalName.Split('@')[0].Replace('.', '')
    }
    
    try {
        $passwordProfile = @{
            Password = $Password
            ForceChangePasswordNextSignIn = $ForcePasswordChange
        }
        
        $userParams = @{
            UserPrincipalName = $UserPrincipalName
            DisplayName = $DisplayName
            MailNickname = $MailNickname
            AccountEnabled = $true
            PasswordProfile = $passwordProfile
        }
        
        $newUser = New-MgUser @userParams
        
        Write-TimestampedMessage "Successfully created user: $($newUser.UserPrincipalName) (ID: $($newUser.Id))"
        
        # Log action to history
        $historyEntry = @"
Date: $(Get-Date -Format 'yyyy-MM-dd')
User: $($env:USERNAME)
Command: New-MgUser -UserPrincipalName '$UserPrincipalName' -DisplayName '$DisplayName'
Purpose: Created new Azure AD user for ThorLabs lab environment
Result: User created successfully with ID $($newUser.Id)
---

"@
        Add-Content -Path "../../history.md" -Value $historyEntry
        
        return $newUser
    }
    catch {
        Write-TimestampedMessage "Failed to create user: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Function to delete a user
function Remove-EntraUser {
    param([string]$UserPrincipalName)
    
    Write-TimestampedMessage "Deleting Azure AD user: $UserPrincipalName"
    
    try {
        # First, verify the user exists
        $user = Get-MgUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
        
        if (-not $user) {
            Write-TimestampedMessage "User not found: $UserPrincipalName" "ERROR"
            throw "User not found"
        }
        
        # Confirm deletion
        $confirmation = Read-Host "Are you sure you want to delete user '$UserPrincipalName'? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-TimestampedMessage "User deletion cancelled."
            return
        }
        
        Remove-MgUser -UserId $user.Id
        
        Write-TimestampedMessage "Successfully deleted user: $UserPrincipalName"
        
        # Log action to history
        $historyEntry = @"
Date: $(Get-Date -Format 'yyyy-MM-dd')
User: $($env:USERNAME)
Command: Remove-MgUser -UserId '$($user.Id)'
Purpose: Deleted Azure AD user from ThorLabs lab environment
Result: User '$UserPrincipalName' deleted successfully
---

"@
        Add-Content -Path "../../history.md" -Value $historyEntry
    }
    catch {
        Write-TimestampedMessage "Failed to delete user: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Main script execution
try {
    Write-TimestampedMessage "Starting ThorLabs Entra ID user management script..."
    
    # Validate prerequisites
    Test-RequiredModules
    Test-GraphConnection
    
    # Execute the requested action
    switch ($Action) {
        "List" {
            Get-EntraUsers
        }
        "Create" {
            if (-not $UserPrincipalName -or -not $DisplayName -or -not $Password) {
                throw "Create action requires UserPrincipalName, DisplayName, and Password parameters."
            }
            New-EntraUser -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -Password $Password -MailNickname $MailNickname -ForcePasswordChange $ForcePasswordChange
        }
        "Delete" {
            if (-not $UserPrincipalName) {
                throw "Delete action requires UserPrincipalName parameter."
            }
            Remove-EntraUser -UserPrincipalName $UserPrincipalName
        }
    }
    
    Write-TimestampedMessage "Script completed successfully."
}
catch {
    Write-TimestampedMessage "Script failed: $($_.Exception.Message)" "ERROR"
    exit 1
}