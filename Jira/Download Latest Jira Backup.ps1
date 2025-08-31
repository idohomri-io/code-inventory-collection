<#
.SYNOPSIS
    downloads a jira backup with retry logic and basic authentication.

.DESCRIPTION
    this script downloads a jira backup zip file using basic authentication.
    it implements retry logic with configurable retry attempts and delays.
    credentials are securely requested and cleared from memory afterward.

.PARAMETER maxRetries
    number of times to retry the download if it fails.

.PARAMETER retryDelaySeconds 
    number of seconds to wait between retries.

.PARAMETER jiraBackupUrl
    the url of the jira backup file.

.PARAMETER outputPath
    the path where the backup file will be saved.

.EXAMPLE
    # run the script and download a jira backup
    .\Download-JiraBackup.ps1
#>
  
# =======================
# configuration
# =======================
$maxRetries         = 5
$retryDelaySeconds  = 10
$jiraBackupUrl      = "https://your-jira-instance/backup/latest"
$outputPath         = ".\jira-backup.zip"

# =======================
# get credentials
# =======================
$credentials = Get-Credential -Message "enter your jira credentials"

# convert credentials to base64 for basic authentication
$base64Auth = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes(
        "$($credentials.UserName):$($credentials.GetNetworkCredential().Password)"
    )
)

# =======================
# retry logic
# =======================
$retryCount = 0
$success    = $false

Write-Host "starting jira backup download..."

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $headers = @{
            Authorization = "Basic $base64Auth"
        }

        # attempt to download the backup
        Invoke-WebRequest -Uri $jiraBackupUrl -Headers $headers -OutFile $outputPath -ErrorAction Stop

        # if successful
        $success = $true
        Write-Host "backup downloaded successfully to: $outputPath"
    }
    catch {
        $retryCount++

        if ($retryCount -lt $maxRetries) {
            Write-Warning "download attempt $retryCount failed. retrying in $retryDelaySeconds seconds..."
            Start-Sleep -Seconds $retryDelaySeconds
        }
        else {
            Write-Error "failed to download jira backup after $maxRetries attempts. error: $($_.Exception.Message)"
        }
    }
}

# =======================
# cleanup
# =======================
$credentials = $null
$base64Auth  = $null
