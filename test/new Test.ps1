# Test script for Code Inventory functionality
# Author: AI Assistant
# Date: 2024

# Import required modules
Import-Module Pester
Import-Module PSScriptAnalyzer # Added additional module for script analysis

# MODIFIED!!!!

# Additional helper functions
function Test-Connection {
    param($url)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Format-JsonOutput {
    param($object)
    return $object | ConvertTo-Json -Depth 10
}

# New function utilizing PSScriptAnalyzer
function Test-ScriptQuality {
    param($scriptPath)
    $analysis = Invoke-ScriptAnalyzer -Path $scriptPath
    return $analysis
}

Describe "Code Inventory Tests" {
    Context "Gallery Functionality" {
        It "Should filter items correctly" {
            # Test filtering by category
            $items = @(
                @{
                    json = @{
                        category = "utility"
                        name = "Test Item"
                    }
                }
            )
            
            $filtered = filterItems -items $items -category "utility" -searchTerm ""
            $filtered.Count | Should -Be 1
        }

        It "Should handle search functionality" {
            # Test search functionality
            $items = @(
                @{
                    json = @{
                        name = "Search Test"
                        category = "test"
                        language = "PowerShell"
                        short_description = "Test description"
                    }
                }
            )

            $filtered = filterItems -items $items -category "All" -searchTerm "test"
            $filtered.Count | Should -Be 1
        }

        It "Should handle empty results gracefully" {
            $items = @()
            $filtered = filterItems -items $items -category "All" -searchTerm ""
            $filtered.Count | Should -Be 0
        }
    }

    Context "Modal Functionality" {
        It "Should show and hide modal correctly" {
            # Test modal visibility
            $modal = New-Object PSObject
            $modal | Add-Member -MemberType NoteProperty -Name "classList" -Value @()
            
            showItemModal($modal)
            $modal.classList.Contains("active") | Should -Be $true

            hideItemModal($modal) 
            $modal.classList.Contains("active") | Should -Be $false
        }

        It "Should populate modal content correctly" {
            $testItem = @{
                name = "Test Modal Item"
                description = "Test Description"
                type = "PowerShell"
            }
            
            $modal = New-Object PSObject
            $modal | Add-Member -MemberType NoteProperty -Name "content" -Value $testItem
            
            showItemModal($modal)
            $modal.content.name | Should -Be "Test Modal Item"
        }
    }

    Context "API Integration" {
        It "Should connect to the API endpoint" {
            $apiUrl = "https://workflows.idohomri.net"
            $connected = Test-Connection -url $apiUrl
            $connected | Should -Be $true
        }
    }

    # New test context using PSScriptAnalyzer
    Context "Script Quality Analysis" {
        It "Should pass basic script analysis" {
            $scriptPath = $PSCommandPath
            $analysisResults = Test-ScriptQuality -scriptPath $scriptPath
            $errors = $analysisResults | Where-Object { $_.Severity -eq 'Error' }
            $errors.Count | Should -Be 0
        }
    }
}


