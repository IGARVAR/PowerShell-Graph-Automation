<#
.SYNOPSIS
Bulk add users from a CSV file to an Active Directory security group.

.DESCRIPTION
This PowerShell script reads user names from a CSV file and adds each corresponding AD user
to a specified Active Directory security group. It logs the result of each operation.

.NOTES
Author: Ivan Garkusha
Filename: Add-Users-To-ADGroup.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- Sufficient privileges to modify AD group membership

USAGE:
- Update $csvPath with the path to your CSV file
- Update $adGroupName with the appropriate group name
- CSV file must contain a column named 'Name'
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Path to the CSV file
$csvPath = ".\\ERG_List.csv"

# Name of the AD security group
$adGroupName = "Example-AD-Group"

# Read the CSV file and process each entry
Import-Csv -Path $csvPath | ForEach-Object {
    # Clean and normalize the username
    $userName = $_.Name.Trim() -replace '\uFEFF', ''

    Write-Output "Processing user: $userName"

    # Query AD using the 'cn' attribute
    $filter = "cn -eq '$userName'"
    $user = Get-ADUser -Filter $filter -ErrorAction SilentlyContinue

    if ($user) {
        try {
            Add-ADGroupMember -Identity $adGroupName -Members $user
            Write-Output "Successfully added $userName to $adGroupName"
        } catch {
            Write-Warning "Failed to add $userName to $adGroupName. Error: $_"
        }
    } else {
        Write-Warning "User $userName not found in Active Directory."
    }
}
