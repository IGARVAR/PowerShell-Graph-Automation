<#
.SYNOPSIS
Exports all public Microsoft Teams into a SharePoint Online list.

.DESCRIPTION
This script connects to Microsoft Teams and a SharePoint Online site.
It retrieves all public Teams, checks if a target SharePoint list exists (creates it if necessary),
and populates it with the team names and (optionally) links to the team.

.REQUIREMENTS
- MicrosoftTeams PowerShell Module
- PnP.PowerShell Module
- Appropriate permissions to Teams and SharePoint

.NOTES
Author: Ivan Garkusha
Date: 2025-06-16
#>

# Connect to Microsoft Teams
Connect-MicrosoftTeams

# SharePoint site and list name (replace with your actual site)
$SharePointSiteURL = "https://yourtenant.sharepoint.com/sites/your-site-name"
$ListName = "MS-public-teams"

# Get all public Teams
$PublicTeams = Get-Team | Where-Object { $_.Visibility -eq "Public" } | Select-Object DisplayName, GroupId

# Connect to SharePoint Online
Connect-PnPOnline -Url $SharePointSiteURL -Interactive

# Check if the list exists, create if not
$ListExists = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
if (-not $ListExists) {
    $ListInfo = New-PnPList -Title $ListName -Template GenericList -OnQuickLaunch
} else {
    $ListInfo = $ListExists
}

# Ensure "Team Link" field exists
$FieldExists = Get-PnPField -List $ListInfo -Identity "TeamLink" -ErrorAction SilentlyContinue
if (-not $FieldExists) {
    Add-PnPField -List $ListInfo -DisplayName "Team Link" -InternalName "TeamLink" -Type URL -AddToDefaultView
}

# Loop through each team and update SharePoint list
foreach ($team in $PublicTeams) {
    $itemValues = @{ "Title" = $team.DisplayName }

    # Optional: generate direct Teams link
    # $tenantId = "<YourTenantId>"
    # $teamLink = "https://teams.microsoft.com/l/team/" + $team.GroupId + "/conversations?groupId=" + $team.GroupId + "&tenantId=$tenantId"
    # $itemValues["TeamLink"] = $teamLink

    $existingItem = Get-PnPListItem -List $ListInfo -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$($team.DisplayName)</Value></Eq></Where></Query></View>"

    if (-not $existingItem) {
        Add-PnPListItem -List $ListInfo -Values $itemValues
    } else {
        Set-PnPListItem -List $ListInfo -Identity $existingItem.Id -Values $itemValues
    }
}

Write-Host "✅ SharePoint list populated with public Teams." -ForegroundColor Green
