# =============================================
# SUMMARY
#   This script generates a report of Active Directory users’ password last-set dates and ages.
#   It imports the ActiveDirectory module if needed, retrieves enabled user accounts,
#   calculates password age, sorts users by age, and displays a color-coded console report.
#
# DEPENDENCIES
#   - ActiveDirectory PowerShell module (Import-Module ActiveDirectory)
#
# USAGE EXAMPLES
#   # Run with default 90-day threshold
#   .\Get-ADPasswordAgeReport.ps1
#
#   # Run with a custom threshold of 60 days
#   .\Get-ADPasswordAgeReport.ps1 -AgeThreshold 60
#
# COPYRIGHT
#   © Ido Homri (idohomri.io)
#   https://inventory.idohomri.io
# =============================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'Number of days after which a password age is considered "old"')]
    [int]
    $AgeThreshold = 90
)

function Import-ADModule {
    <#  
    .SYNOPSIS
        import active directory module if not loaded
    .DESCRIPTION
        Checks for the ActiveDirectory module and loads it with error handling.
    #>
    if (-not (Get-Module -Name ActiveDirectory)) {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
}

function Get-EnabledADUsers {
    <#
    .SYNOPSIS
        retrieve enabled ad user accounts
    .DESCRIPTION
        Fetches all enabled user objects from Active Directory including password last-set date.
    #>
    Get-ADUser -Filter 'Enabled -eq $true' -Properties Name, PasswordLastSet
}

function Compute-PasswordAge {
    <#
    .SYNOPSIS
        compute password age in days or mark as never
    .PARAMETER UserObject
        ad user object with PasswordLastSet property
    .PARAMETER ReferenceDate
        date to calculate age from (usually today)
    .OUTPUTS
        PSCustomObject with Name, PasswordLastSet, PasswordAge
    #>
    param(
        [Parameter(Mandatory)] $UserObject,
        [Parameter(Mandatory)] [datetime] $ReferenceDate
    )

    if ($UserObject.PasswordLastSet) {
        $ageDays = [math]::Round(($ReferenceDate - $UserObject.PasswordLastSet).TotalDays)
    }
    else {
        $ageDays = 'Never'
    }

    [PSCustomObject]@{
        Name            = $UserObject.Name
        PasswordLastSet = $UserObject.PasswordLastSet
        PasswordAge     = $ageDays
    }
}

function Sort-UsersByPasswordAge {
    <#
    .SYNOPSIS
        sort users by password age descending
    .DESCRIPTION
        Treats 'Never' as highest age so those users appear first.
    #>
    param(
        [Parameter(Mandatory)] [array] $UserList
    )

    $UserList | Sort-Object @{ Expression = {
            if ($_.PasswordAge -eq 'Never') { [int]::MaxValue } 
            else { $_.PasswordAge }
        }; Descending = $true }
}

function Display-PasswordAgeReport {
    <#
    .SYNOPSIS
        output the password age report to console
    .DESCRIPTION
        Writes header, each user entry with color coding, and footer.
    .PARAMETER Users
        sorted list of PSCustomObjects with password age info
    .PARAMETER Threshold
        age threshold for determining warning color
    #>
    param(
        [Parameter(Mandatory)] [array] $Users,
        [Parameter(Mandatory)] [int] $Threshold
    )

    $now = Get-Date

    Write-Host "`nPassword Last Set Report" -ForegroundColor Cyan
    Write-Host "Generated on: $($now.ToString('yyyy-MM-dd HH:mm:ss'))`n" -ForegroundColor Gray
    Write-Host ('=' * 80) -ForegroundColor DarkGray

    foreach ($user in $Users) {
        # choose color: red for never, yellow if older than threshold, green otherwise
        $color = switch ($user.PasswordAge) {
            'Never' { 'Red' }
            { $_ -gt $Threshold } { 'Yellow' }
            default { 'Green' }
        }

        Write-Host "User               : $($user.Name)" -ForegroundColor White
        Write-Host "Password Last Set  : $(if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString('yyyy-MM-dd') } else { 'Never' })"
        Write-Host ("Password Age (days): $($user.PasswordAge)") -ForegroundColor $color
        Write-Host ('-' * 80) -ForegroundColor DarkGray
    }

    Write-Host "`nReport Complete`n" -ForegroundColor Cyan
}

function Main {
    <#
    .SYNOPSIS
        main entry point for script execution
    .DESCRIPTION
        orchestrates import, retrieval, computation, sorting, and display of the report.
    #>
    Import-ADModule

    $today = Get-Date
    $rawUsers    = Get-EnabledADUsers
    $computed    = $rawUsers | ForEach-Object { Compute-PasswordAge -UserObject $_ -ReferenceDate $today }
    $sortedUsers = Sort-UsersByPasswordAge -UserList $computed

    Display-PasswordAgeReport -Users $sortedUsers -Threshold $AgeThreshold
}

# execute the script
Main

# © Ido Homri (idohomri.io)
# https://inventory.idohomri.io
