
param(
    [Parameter(Mandatory = $false)]
    [string]$DomainController,
    
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [string]$Filter = "Enabled -eq $true",
    
    [Parameter(Mandatory = $false)]
    [string[]]$Properties = @(
        "SamAccountName",
        "DisplayName", 
        "GivenName",
        "Surname",
        "EmailAddress",
        "Department",
        "Title",
        "Manager",
        "LastLogonDate",
        "Created",
        "Enabled",
        "PasswordLastSet",
        "PasswordExpires",  
        "LockedOut",
        "DistinguishedName"
    ),
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to test AD connectivity
function Test-ADConnectivity {
    param(
        [string]$DC,
        [System.Management.Automation.PSCredential]$Cred
    )
    
    try {
        $testParams = @{
            Server = $DC
            ErrorAction = "Stop"
        }
        
        if ($Cred) {
            $testParams.Credential = $Cred
        }
        
        $testResult = Get-ADDomain @testParams
        return $true
    }
    catch {
        Write-ColorOutput "Failed to connect to Active Directory: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
try {
    Write-ColorOutput "=== Active Directory User Fetch Script ===" "Cyan"
    Write-ColorOutput "Starting user retrieval process..." "Yellow"
    
    # Build the Get-ADUser parameters
    $adParams = @{
        Filter = $Filter
        Properties = $Properties
        ErrorAction = "Stop"
    }
    
    # Add domain controller if specified
    if ($DomainController) {
        $adParams.Server = $DomainController
        Write-ColorOutput "Using domain controller: $DomainController" "Green"
    }
    
    # Add credentials if specified
    if ($Credential) {
        $adParams.Credential = $Credential
        Write-ColorOutput "Using custom credentials" "Green"
    }
    
    # Test connectivity before proceeding
    if (-not (Test-ADConnectivity -DC $DomainController -Cred $Credential)) {
        throw "Cannot connect to Active Directory. Please check your connection and credentials."
    }
    
    Write-ColorOutput "Retrieving users with filter: $Filter" "Yellow"
    
    # Get all users
    $users = Get-ADUser @adParams
    
    if ($users) {
        $userCount = $users.Count
        Write-ColorOutput "Successfully retrieved $userCount users from Active Directory" "Green"
        
        # Display summary
        Write-ColorOutput "`n=== User Summary ===" "Cyan"
        $users | Group-Object Enabled | ForEach-Object {
            $status = if ($_.Name -eq "True") { "Enabled" } else { "Disabled" }
            Write-ColorOutput "$status Users: $($_.Count)" "White"
        }
        
        # Display first 10 users as sample
        Write-ColorOutput "`n=== Sample Users (First 10) ===" "Cyan"
        $users | Select-Object -First 10 | Format-Table -AutoSize -Property SamAccountName, DisplayName, Department, Enabled, LastLogonDate
        
        # Export to CSV if path specified
        if ($ExportPath) {
            try {
                $users | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
                Write-ColorOutput "`nUsers exported to: $ExportPath" "Green"
            }
            catch {
                Write-ColorOutput "Failed to export to CSV: $($_.Exception.Message)" "Red"
            }
        }
        
        # Return the users object for further processing
        return $users
    }
    else {
        Write-ColorOutput "No users found matching the specified filter." "Yellow"
        return @()
    }
}
catch {
    Write-ColorOutput "Error occurred: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}
finally {
    Write-ColorOutput "`nScript execution completed." "Cyan"
}
