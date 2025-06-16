<#
.SYNOPSIS
Automates Microsoft Teams creation and associated Active Directory group provisioning based on request data from Microsoft Forms (CSV export).

.DESCRIPTION
This script processes approved team creation requests exported from Microsoft Forms. For each request:
- Validates input fields
- Creates a Microsoft Team (if not already existing)
- Creates a corresponding AD security group
- Sets group classification attributes (info, extensionAttribute1/2/11)
- Optionally adds members from a ROLE-based group
- Sends log output to file and screen

.NOTES
Author: Ivan Garkusha
Filename: AD_AUTOMATE_Create_MS_Teams_with_RES_Group.ps1
Version: 2.0

.REQUIREMENTS
- MicrosoftTeams PowerShell Module
- ActiveDirectory PowerShell Module
- Credential file via Export-CliXml

.USAGE
1. Export Microsoft Forms responses to CSV
2. Set `$CsvFilePath` to the exported file
3. Prepare credential file:
   `Get-Credential | Export-CliXml -Path "$env:USERPROFILE\MsTeamsAdmin.Cred"`
4. Execute script in elevated PowerShell session

.INPUT
- CSV headers expected:
  "Team name", "Team purpose", "Team owner", "Confidentiality levels", 
  "Personal data classification", "Public or private Team", 
  "Role name", "Current status", "Ticket ID"

#>

# Global Variables
$CsvFilePath = "E:\Scripts\CreateMSTeams\Requests.csv"
$LogDirectory = "E:\Scripts\CreateMSTeams\Logs"
$CredentialFilePath = "${env:USERPROFILE}\MsTeamsAdmin.Cred"

# Logging Function
Function Log-Text($Message) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "$timestamp - $Message"
    if (-not (Test-Path $LogDirectory)) { New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null }
    "$timestamp - $Message" | Out-File -FilePath "$LogDirectory\CreateMSTeams_$(Get-Date -Format 'yyyyMMdd').log" -Append -Encoding UTF8
}

# Start Logging
Log-Text "SCRIPT STARTED"

# Validate CSV File
if (-not (Test-Path $CsvFilePath)) { Log-Text "CSV file not found"; Exit 1 }
$requests = Import-Csv -Path $CsvFilePath | Where-Object { $_.'Current status' -eq 'Approved' -and $_.'Ticket ID' -ne '' }
if (-not $requests) { Log-Text "No requests to process."; Exit 0 }
Log-Text "$($requests.Count) requests to process."

# Connect to Microsoft Teams
Try {
    if (-not (Test-Path $CredentialFilePath)) { Throw "Credential file not found" }
    $CREDENTIAL = Import-CliXml -Path $CredentialFilePath
    Connect-MicrosoftTeams -Credential $CREDENTIAL
    Log-Text "Connected to Microsoft Teams"
} Catch { Log-Text "Teams Connection Failed: $_"; Exit 1 }

# Process Each Request
foreach ($request in $requests) {
    Try {
        # **Validations & Data Extraction**
        [string]$tmDisplayName = $request.'Team name'.Trim()
        $tmAlias = $tmDisplayName -replace '[^\w-]', ''
        $tmAlias = if ($tmAlias.Length -gt 64) { $tmAlias.Substring(0, 63) } else { $tmAlias }
        $tmAliasModified = $tmAlias.ToUpper().Replace("_", "-")
        [string]$tmDescription = $request.'Team purpose'
        [string]$tmOwner = $request.'Team owner'.Trim()
        [string]$tmConfidentiality = $request.'Confidentiality levels'.Trim()
        [string]$tmPersonal = $request.'Personal data classification'.Trim()

        # Determine Visibility
        $tmVisibility = switch -wildcard ($request.'Public or private Team'.Trim().ToLower()) {
            "public*" { "Public" }
            "private*" { "Private" }
            default { Throw "Invalid team visibility: $($request.'Public or private Team')" }
        }
        Log-Text "Processing Team: $tmDisplayName (Visibility: $tmVisibility)"

        # Validate Owner in AD
        $ownerADUser = Get-ADUser -Filter { UserPrincipalName -eq $tmOwner } -Properties GivenName, UserPrincipalName -ErrorAction SilentlyContinue
        if (-not $ownerADUser) { Throw "Owner $tmOwner not found in AD" }

        # Check if Team Exists
        $existingTeam = Get-Team -DisplayName $tmDisplayName -ErrorAction SilentlyContinue
        if ($existingTeam) {
            Log-Text "Team exists: $tmDisplayName (Skipping creation)"
            $teamID = $existingTeam.GroupId
        } else {
            $tmGroup = New-Team -DisplayName $tmDisplayName -Description $tmDescription -MailNickName $tmAliasModified -Owner $tmOwner -Visibility $tmVisibility
            if (-not $tmGroup) { Throw "Failed to create team" }
            $teamID = $tmGroup.GroupId
            Log-Text "Team Created: $tmDisplayName (ID: $teamID)"
        }

        # AD Group Creation
        $adGroupName = "RES_O365_TEAMS-${tmAliasModified}_MEMBERS"
        $existingADGroup = Get-ADGroup -Filter { Name -eq $adGroupName } -ErrorAction SilentlyContinue

        if ($existingADGroup) {
            Log-Text "AD Group Exists: $adGroupName (Skipping creation)"
        } else {
            $adGroup = New-ADGroup -Name $adGroupName -Description "Access to Microsoft Team: $tmDisplayName" `
                -ManagedBy $ownerADUser -Path "OU=Cloud,OU=Groups,DC=yourdomain,DC=local" `
                -GroupCategory Security -GroupScope Universal -PassThru

            # Set Attributes
            Set-ADGroup -Identity $adGroup -Add @{
                info = "Access to Microsoft Team: $tmDisplayName"
                extensionattribute1 = $tmConfidentiality
                extensionattribute2 = $tmPersonal
                extensionattribute11 = $teamID
            }

            Log-Text "AD Group Created & Attributes Set: $adGroupName"
        }

        # Add ROLE Members if applicable
        $tmMemberGroup = $request.'Role name'
        if ($tmMemberGroup -and (Get-ADGroup -Filter { SamAccountName -eq $tmMemberGroup } -ErrorAction SilentlyContinue)) {
            Add-ADGroupMember -Identity $adGroupName -Members $tmMemberGroup -ErrorAction Stop
            Log-Text "Added members from $tmMemberGroup to $adGroupName"
        } else {
            Log-Text "Skipping ROLE Group addition: $tmMemberGroup not found"
        }

    } Catch {
        Log-Text "Error processing ${tmDisplayName}: $_"
        Continue
    }
}

# Disconnect & Cleanup
Disconnect-MicrosoftTeams -Confirm:$false

# Remove Variables
Remove-Variable -Name tmDisplayName, tmAlias, tmAliasModified, tmDescription, tmOwner, tmConfidentiality, tmPersonal, tmVisibility, tmMemberGroup, tmGroup, adGroup, CREDENTIAL, requests -ErrorAction SilentlyContinue

Log-Text "SCRIPT FINISHED"
