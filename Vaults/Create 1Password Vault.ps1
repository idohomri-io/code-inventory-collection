<#
.SYNOPSIS
    Creates a new 1Password vault using a service account token. 
   
.DESCRIPTION
    This script defines a function that uses the 1Password CLI to authenticate
    with a service account token and create a new vault with the specified name.

.DEPENDENCIES
    - 1Password CLI (op): https://developer.1password.com/docs/cli/

.PARAMETER ServiceAccountToken
    The 1Password service account token.

.PARAMETER VaultName
    The name of the vault to be created.

.EXAMPLE
    # Import the script and call the function directly
    . .\Create-1PasswordVault.ps1
    Create-1PasswordVault -ServiceAccountToken "op://token/12345" -VaultName "MyNewVault"

.EXAMPLE
    # Execute as a standalone script
    .\Create-1PasswordVault.ps1 -ServiceAccountToken "op://token/12345" -VaultName "MyNewVault"

#>

# summary:
# define a function to create a 1password vault using a service account token,
# handling authentication, error checking, and cleanup.
#
# use cases:
# - automation pipelines that need to provision vaults dynamically.
# - administrative scripts for onboarding new teams or projects.
#
# copyright:
#   © Ido Homri (idohomri.io)
#   https://inventory.idohomri.io

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ServiceAccountToken,

    [Parameter(Mandatory = $true)]
    [string] $VaultName
)

function Create-1PasswordVault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ServiceAccountToken,

        [Parameter(Mandatory = $true)]
        [string] $VaultName
    )

    # ensure 1password cli is installed and accessible
    if (-not (Get-Command "op" -ErrorAction SilentlyContinue)) {
        Write-Error "1Password CLI ('op') is not installed or not in PATH."
        return 1
    }

    try {
        # authenticate with service account token
        $env:OP_SERVICE_ACCOUNT_TOKEN = $ServiceAccountToken

        # create the vault and capture json result
        Write-Host "Creating new vault '$VaultName'..."
        $jsonResult = op vault create $VaultName --format json 2>&1

        # check exit code for success
        if ($LASTEXITCODE -eq 0) {
            # parse and display vault details
            $vault = $jsonResult | ConvertFrom-Json
            Write-Host "Vault created successfully!"
            Write-Host "  id  : $($vault.id)"
            Write-Host "  name: $($vault.name)"
            return 0
        }
        else {
            # report failure details
            Write-Error "Failed to create vault. Error: $jsonResult"
            return $LASTEXITCODE
        }
    }
    catch {
        # catch any unexpected errors
        Write-Error "An unexpected error occurred: $_"
        return 1
    }
    finally {
        # cleanup the environment variable
        Remove-Item Env:\OP_SERVICE_ACCOUNT_TOKEN -ErrorAction SilentlyContinue
    }
}

# execute function when script is run directly
if ($PSCommandPath -eq $MyInvocation.MyCommand.Path) {
    Create-1PasswordVault -ServiceAccountToken $ServiceAccountToken -VaultName $VaultName
}

# end of script

# © Ido Homri (idohomri.io)
# https://inventory.idohomri.io
