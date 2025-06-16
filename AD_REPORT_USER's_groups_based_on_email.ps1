<#
.SYNOPSIS
Retrieves all AD groups managed by a user, based on their email address.

.DESCRIPTION
This script queries Active Directory to find a user by their email (mail attribute), retrieves their Distinguished Name,
and lists all groups where this user is set as the ManagedBy owner.

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_USERs_groups_based_on_email.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- Read access to user and group directory objects

USAGE:
- Update the $email variable with the user's email address
- The script will output a list of groups managed by that user
#>

# Define the email address to search by (update before use)
$email = "user@example.com"

# Find the user by email and retrieve their Distinguished Name
$user = Get-ADUser -Filter {mail -eq $email} -Properties DistinguishedName

if ($user.DistinguishedName) {
    # Retrieve all AD groups where this user is the manager
    $managedGroups = Get-ADGroup -Filter "ManagedBy -eq '$($user.DistinguishedName)'"

    # Output the results
    $managedGroups | Select-Object Name, ManagedBy
} else {
    Write-Host "Unable to retrieve the DistinguishedName for the user with email: $email."
}
