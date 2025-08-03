<#
.SYNOPSIS
Retrieves detailed information for an Active Directory user.

.DESCRIPTION
This script defines a function, Get-ADUserInfo, that fetches a user's details
from Active Directory, including name, email, title, manager, and account status.
It handles errors gracefully and highlights disabled accounts in red.

.EXAMPLE
# Get information for user 'jdoe'
Get-ADUserInfo -Username "jdoe"
# Or call interactively:
# .\Get-ADUserInfo.ps1 -Interactive
#
# This will prompt for a username if -Interactive is used.
#
# NOTE:
# Ensure the ActiveDirectory module is available and you have sufficient
# permissions to query AD.
#>
   
# import the Active Directory module if not already loaded
if (-not (Get-Module -Name ActiveDirectory)) {
    Import-Module ActiveDirectory
}

<#
    .PARAMETER Username
    The samAccountName or distinguished name of the AD user to query.
#>
function Get-ADUserInfo {
    [CmdletBinding()]
    param (
        # the AD user's identity
        [Parameter(Mandatory = $false)]
        [string] $Username,

        # switch to prompt for username interactively
        [switch] $Interactive
    )

    # if interactive prompt is requested, ask for username
    if ($Interactive) {
        $Username = Read-Host -Prompt 'Enter AD username'
    }

    try {
        # retrieve all properties for the specified user
        $user = Get-ADUser -Identity $Username -Properties Name, EmailAddress, Title, Manager, Enabled

        if ($null -ne $user) {
            Write-Host "User found:" -ForegroundColor Green
            Write-Host "  Name:      $($user.Name)"
            Write-Host "  Email:     $($user.EmailAddress)"
            Write-Host "  Title:     $($user.Title)"

            # resolve manager name if set
            if ($user.Manager) {
                $managerObj = Get-ADUser -Identity $user.Manager -Properties Name
                Write-Host "  Manager:   $($managerObj.Name)"
            } else {
                Write-Host "  Manager:   <none>"
            }

            Write-Host "  Enabled:   $($user.Enabled)"

            # highlight disabled accounts
            if (-not $user.Enabled) {
                Write-Host '  Account disabled!' -ForegroundColor Red
            }
        } else {
            Write-Host "User '$Username' not found." -ForegroundColor Yellow
        }
    }
    catch {
        # display error message
        Write-Error "Failed to retrieve user information: $_"
    }
}

<#
    # usage examples:
    # Get-ADUserInfo -Username 'jdoe'
    # Get-ADUserInfo -Interactive
#>

# if script is called directly, invoke function
if ($MyInvocation.MyCommand.Path -eq $PSCommandPath) {
    # default to interactive if no parameters provided
    if (-not $PSBoundParameters.ContainsKey('Username')) {
        Get-ADUserInfo -Interactive
    } else {
        Get-ADUserInfo @PSBoundParameters
    }
}
