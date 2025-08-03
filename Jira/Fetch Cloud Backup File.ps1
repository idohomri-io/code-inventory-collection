param(
    [Parameter(Mandatory = $true)]
    [string]$JiraUrl,
    
    [Parameter(Mandatory = $true)] 
    [string]$ApiToken,
    
    [Parameter(Mandatory = $true)]
    [string]$UserEmail,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\backup.zip"
)

# Base64 encode credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${UserEmail}:${ApiToken}"))

# Build headers
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    Accept = "application/json"
}

# Construct URL
$backupUrl = "$JiraUrl/rest/backup/1/export/runbackup"

Write-Host "Fetching Jira backup from $JiraUrl..." -ForegroundColor Cyan

# Download backup using curl
$curlCmd = "curl -X GET `"$backupUrl`" -H `"Authorization: Basic $base64AuthInfo`" -H `"Accept: application/json`" --output `"$OutputPath`""
Invoke-Expression $curlCmd

if (Test-Path $OutputPath) {
    Write-Host "Backup downloaded successfully to: $OutputPath" -ForegroundColor Green
} else {
    Write-Host "Failed to download backup" -ForegroundColor Red
}
