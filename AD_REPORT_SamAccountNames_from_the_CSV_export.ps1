<#
.SYNOPSIS
Looks up SamAccountNames in Active Directory using email addresses from a CSV file.

.DESCRIPTION
This script reads a CSV file containing userPrincipalName values and queries Active Directory
to find corresponding user accounts. It then outputs each user's SamAccountName if found.

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_SamAccountNames_from_the_CSV_export.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- CSV file must contain a column named 'userPrincipalName'

USAGE:
- Update the $csvPath variable to point to the input file
- Optional: Add export to file or logging as needed
#>

# Path to the input CSV file
$csvPath = ".\\UserEmailList.csv"

# Import the list of users from the CSV
$userList = Import-Csv -Path $csvPath

# Iterate through each user entry
foreach ($user in $userList) {
    $email = $user.userPrincipalName

    # Search AD by email address
    $adUser = Get-ADUser -Filter "mail -eq '$email'" -Properties SamAccountName, mail

    if ($adUser) {
        Write-Output $adUser.SamAccountName
    } else {
        Write-Output "User with email '$email' not found."
    }
}
