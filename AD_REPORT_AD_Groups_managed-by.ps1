<#
.SYNOPSIS
Reports all Active Directory groups managed by a specified user.

.DESCRIPTION
This script retrieves and displays all Active Directory groups where the 'ManagedBy' attribute matches
the distinguished name of a given user.

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_AD_Groups_managed-by.ps1

REQUIREMENTS:
- Active Directory PowerShell module

USAGE:
- Set $ManagerName to the display name (Name attribute) of the user
- Script will output a formatted table of group names and their managers
#>

# Define the display name of the manager
$ManagerName = "John Doe"

# Retrieve the distinguished name (DN) of the specified manager
$UserDN = (Get-ADUser -Filter {Name -eq $ManagerName}).DistinguishedName

if ($UserDN) {
    # Get all groups where the manager is listed as 'ManagedBy'
    $ManagedGroups = Get-ADGroup -Filter {ManagedBy -eq $UserDN} -Properties Name, ManagedBy

    if ($ManagedGroups) {
        # Display results
        $ManagedGroups | Select-Object Name, ManagedBy | Format-Table -AutoSize
    } else {
        Write-Host "No groups managed by $ManagerName were found." -ForegroundColor Yellow
    }
} else {
    Write-Host "User '$ManagerName' not found in Active Directory." -ForegroundColor Red
}
