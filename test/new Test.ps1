# Test script for Code Inventory functionality
# Author: AI Assistant
# Date: 2024

# Import required modules
Import-Module Pester

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
    }
}
