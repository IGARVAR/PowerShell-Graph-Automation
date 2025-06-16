<#
.SYNOPSIS
Exports all Microsoft Teams owners and compares them with a specific AD security group.

.DESCRIPTION
This script connects to Microsoft Teams and retrieves all owners of each Team.
It then compares the list of owners with the members of a specified AD security group
to identify mismatches.

.REQUIREMENTS
- MicrosoftTeams PowerShell Module
- ActiveDirectory Module
- Proper permissions to query Teams and AD

.NOTES
Author: Ivan Garkusha
Date: 2025-06-16
#>

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Fetch all Teams
$teams = Get-Team

# Prepare the CSV data
$csvData = @()

foreach ($team in $teams) {
    $teamId = $team.GroupId
    $teamName = $team.DisplayName

    # Get team members and filter owners
    $owners = Get-TeamUser -GroupId $teamId | Where-Object { $_.Role -eq "Owner" }

    foreach ($owner in $owners) {
        $csvData += [PSCustomObject]@{
            "Team Name"   = $teamName
            "Team ID"     = $teamId
            "Owner Name"  = $owner.Name
            "Owner Email" = $owner.User
            "Owner Role"  = $owner.Role
        }
    }
}

# Export to CSV (you may change path as needed)
$outputPath = ".\TeamsOwners.csv"
$csvData | Export-Csv -Path $outputPath -NoTypeInformation
Write-Host "✅ Exported Teams owners to $outputPath" -ForegroundColor Green

# Disconnect if desired
# Disconnect-MicrosoftTeams

# Compare with AD Group (optional section below)

# Import CSV
$teamsOwnersCsv = Import-Csv -Path $outputPath

# Define AD group name (replace with your actual group)
$adGroupName = "ROLE_Global_TeamOwners"

# Get members of the AD security group
$adGroupMembers = Get-ADGroupMember -Identity $adGroupName -Recursive | Get-ADUser -Property Mail | Select-Object -ExpandProperty Mail

# Normalize and clean email addresses
$adGroupMembers = $adGroupMembers | Where-Object { $_ } | ForEach-Object { $_.Trim().ToLower() }
$teamsOwners = $teamsOwnersCsv | ForEach-Object { $_.'Owner Email'.Trim().ToLower() }

# Compare
$notInTeams = $adGroupMembers | Where-Object { $_ -notin $teamsOwners }
$notInAD = $teamsOwners | Where-Object { $_ -notin $adGroupMembers }

# Output differences
Write-Host "`n📤 AD Group Members not in Teams Owners:"
$notInTeams | ForEach-Object { Write-Host " - $_" }

Write-Host "`n📥 Teams Owners not in AD Group:"
$notInAD | ForEach-Object { Write-Host " - $_" }
