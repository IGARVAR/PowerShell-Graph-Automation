<#
.SYNOPSIS
Exports a list of security groups from a specified Active Directory Organizational Unit (OU).

.DESCRIPTION
This script queries all AD security groups within a specified OU and exports their
Name, Description, DisplayName, and Info properties to a CSV report.

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_Seq_Groups_DisplayName_OU.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- Read access to the specified OU

USAGE:
- Update $OU to the distinguished name (DN) of your target OU
- Update $CSVPath as needed to control output location
#>

# Define the target Organizational Unit (update as needed)
$OU = "OU=Example,OU=Groups,DC=contoso,DC=com"

# Retrieve security groups within the OU
$SecurityGroups = Get-ADGroup -Filter * -SearchBase $OU -Properties Description, DisplayName, Info

# Select desired fields
$Report = $SecurityGroups | Select-Object Name, Description, DisplayName, Info

# Output file path
$CSVPath = ".\\AD_SecurityGroups_Report.csv"

# Export results to CSV
$Report | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8

# Display confirmation and data
Write-Host "The report has been saved to $CSVPath"
$Report
