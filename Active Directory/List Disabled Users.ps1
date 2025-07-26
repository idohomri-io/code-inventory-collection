# Import the AD module
Import-Module ActiveDirectory

# Define the list of msDS attributes you're interested in
$msdsAttributes = @(
    'msDS-UserAccountDisabled',
    'msDS-LastSuccessfulInteractiveLogonTime',
    'msDS-UserPasswordExpiryTimeComputed',
    'msDS-ResultantPSO',
    'msDS-User-Account-Control-Computed'
)

# Get all AD users
$users = Get-ADUser -Filter * -Properties $msdsAttributes + 'Enabled', 'SamAccountName'

# Prepare result list
$results = foreach ($user in $users) {
    [PSCustomObject]@{
        SamAccountName                     = $user.SamAccountName
        Enabled                            = $user.Enabled
        'msDS-UserAccountDisabled'         = $user.'msDS-UserAccountDisabled'
        'msDS-LastSuccessfulInteractiveLogonTime' = $user.'msDS-LastSuccessfulInteractiveLogonTime'
        'msDS-UserPasswordExpiryTimeComputed'     = $user.'msDS-UserPasswordExpiryTimeComputed'
        'msDS-ResultantPSO'                       = $user.'msDS-ResultantPSO'
        'msDS-User-Account-Control-Computed'      = $user.'msDS-User-Account-Control-Computed'
    }
}

# Output results to the console or export to CSV
$results | Format-Table -AutoSize
# Optionally, export to CSV:
# $results | Export-Csv -Path "ADUsers_msDS_Check.csv" -NoTypeInformation

# bla bla bla sdfads