<#
.SYNOPSIS
    Automates creating and initiating a Jira Cloud backup via REST API.
.DESCRIPTION
    This script authenticates to Jira Cloud using basic auth, calls the backup endpoint,
    and outputs the backup task ID or error details.
.NOTES
    - Requires PowerShell 5.1+ (or PowerShell Core)
    - Ensure execution policy allows running scripts: Set-ExecutionPolicy RemoteSigned
    - Protect your API token securely (e.g., use environment variables or a secure vault)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$JiraBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$ApiToken,

    [Parameter(Mandatory = $true)]
    [string]$UserEmail
)   

# <summary>
#   Converts user credentials into a Base64-encoded string for basic authentication.
# </summary>
function Get-AuthHeader {
    param(
        [string]$Email,
        [string]$Token
    )

    # construct and encode credentials
    $rawCreds = "$Email`:$Token"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($rawCreds))
    return @{ Authorization = "Basic $encoded" }
}

# <summary>
#   Initiates a Jira backup and returns the task ID.
# </summary>
function Invoke-JiraBackup {
    param(
        [string]$BaseUrl,
        [hashtable]$AuthHeader
    )

    # endpoint for backup
    $uri = "$BaseUrl/rest/backup/1/export/runbackup"

    try {
        # call REST API
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $AuthHeader -ContentType 'application/json' -Accept 'application/json'

        if ($response.taskId) {
            Write-Host "Backup initiated successfully. Task ID: $($response.taskId)"
        } else {
            Write-Warning "Backup initiated but no task ID returned."
        }

        return $response
    } catch {
        # output error details and exit
        Write-Error "Failed to initiate backup: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
            Write-Error "Status Description: $($_.Exception.Response.StatusDescription)"
        }
        exit 1
    }
}

<#
.USAGE
    # Example: initiate backup with inline parameters
    .\JiraBackup.ps1 -JiraBaseUrl "https://your-domain.atlassian.net" -ApiToken "your-api-token" -UserEmail "admin@domain.com"

    # Example: prompt for secure input
    $token = Read-Host -AsSecureString "Enter API Token" | ConvertFrom-SecureString
    .\JiraBackup.ps1 -JiraBaseUrl "https://your-domain.atlassian.net" -ApiToken (ConvertTo-SecureString $token) -UserEmail "admin@domain.com"
#>

# main execution
$authHeader = Get-AuthHeader -Email $UserEmail -Token $ApiToken
Invoke-JiraBackup -BaseUrl $JiraBaseUrl -AuthHeader $authHeader
