<#
.SYNOPSIS
    Generates a report of Active Directory users’ password last-set dates and ages.

.DESCRIPTION
    This script imports the ActiveDirectory module (if needed), retrieves all enabled user accounts,
    calculates the number of days since each password was last set (or marks as ‘Never’),
    sorts users by password age (oldest first), and displays a color-coded console report.

.PARAMETER AgeThreshold
    Optional integer. Number of days after which a password age is considered “old” (defaults to 90).

.EXAMPLE
    # Run with default 90-day threshold
    .\Get-ADPasswordAgeReport.ps1

.EXAMPLE
    # Run with a custom threshold of 60 days
    .\Get-ADPasswordAgeReport.ps1 -AgeThreshold 60

.NOTES
    - Requires the ActiveDirectory PowerShell module.
    - Must be run with an account that can read user objects in AD.
    - Colors: Red = never set, Yellow = older than threshold, Green = within threshold.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]
    $AgeThreshold = 90
)

#region summary
# summary:
#   - import active directory module if not already loaded
#   - gather enabled user accounts and properties: name, password last set
#   - compute password age in days or 'Never' if unset
#   - sort by descending age (never-set at top)
#   - write a color-coded console report
#endregion

# ensure the ActiveDirectory module is available
if (-not (Get-Module -Name ActiveDirectory)) {
    # load module to access Get-ADUser
    Import-Module ActiveDirectory -ErrorAction Stop
}

# get current date for calculations
$today = Get-Date

# retrieve enabled users with relevant properties
$rawUsers = Get-ADUser -Filter 'Enabled -eq $true' -Properties PasswordLastSet, Name

# compute password age and prepare objects
$users = $rawUsers | ForEach-Object {
    # determine age days or label as 'Never'
    if ($_.PasswordLastSet) {
        $ageDays = [math]::Round(($today - $_.PasswordLastSet).TotalDays)
    }
    else {
        $ageDays = 'Never'
    }

    # output a PSCustomObject for clarity
    [PSCustomObject]@{
        Name            = $_.Name
        PasswordLastSet = $_.PasswordLastSet
        PasswordAge     = $ageDays
    }
}

# sort: treat 'Never' as highest possible age so they appear first
$sortedUsers = $users |
    Sort-Object @{
        Expression = {
            if ($_.PasswordAge -eq 'Never') {
                [int]::MaxValue
            }
            else {
                $_.PasswordAge
            }
        }
        Descending = $true
    }

# display header
Write-Host "`nPassword Last Set Report" -ForegroundColor Cyan
Write-Host "Generated on: $($today.ToString('yyyy-MM-dd HH:mm:ss'))`n" -ForegroundColor Gray
Write-Host ('=' * 80) -ForegroundColor DarkGray

# output each user with color coding
foreach ($user in $sortedUsers) {
    # choose color: red for never, yellow for old, green otherwise
    $color = switch ($user.PasswordAge) {
        'Never' { 'Red' }
        { $_ -gt $AgeThreshold } { 'Yellow' }
        default { 'Green' }
    }

    # write user info
    Write-Host "User               : $($user.Name)" -ForegroundColor White
    Write-Host "Password Last Set  : $(if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString('yyyy-MM-dd') } else { 'Never' })"
    Write-Host ("Password Age (days): $($user.PasswordAge)") -ForegroundColor $color
    Write-Host ('-' * 80) -ForegroundColor DarkGray
}

# footer
Write-Host "`nReport Complete`n" -ForegroundColor Cyan
