<#
.SYNOPSIS
Reports details about an Active Directory group using extensionAttribute11, including group members and management hierarchy.

.DESCRIPTION
This script finds a security group based on a specific value in extensionAttribute11, then displays:
- Group name and extensionAttribute11
- Group's manager (if any)
- All group members
- For each nested group, its manager (if any)

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_MSteams_ID_to_RES_group_with_all.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- Permissions to read group and user attributes

USAGE:
- Set $targetExtensionAttribute11 to the GUID or unique value used for identification
- This script is useful for Teams / M365 group mapping and ownership visibility
#>

# Define the target extensionAttribute11 value (replace with actual if needed)
$targetExtensionAttribute11 = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Find the AD group using extensionAttribute11
$group = Get-ADGroup -Filter "extensionAttribute11 -eq '$targetExtensionAttribute11'" -Properties extensionAttribute11, managedBy

if ($group) {
    Write-Host "Group name: $($group.Name)"
    Write-Host "ExtensionAttribute11: $($group.extensionAttribute11)"

    # Get manager info if present
    $managerName = "No owner assigned"
    if ($group.managedBy) {
        $manager = Get-ADUser -Identity $group.managedBy -Properties DisplayName
        $managerName = $manager.DisplayName
    }
    Write-Host "Managed by: $managerName"

    # List group members
    Write-Host "Members and their managers (if applicable):"
    $members = Get-ADGroupMember -Identity $group.SamAccountName

    foreach ($member in $members) {
        Write-Host "  * Member: $($member.Name)"

        if ($member.objectClass -eq 'group') {
            $nestedGroup = Get-ADGroup -Identity $member.DistinguishedName -Properties managedBy
            $nestedManagerName = "No owner assigned"

            if ($nestedGroup.managedBy) {
                $nestedManager = Get-ADUser -Identity $nestedGroup.managedBy -Properties DisplayName
                $nestedManagerName = $nestedManager.DisplayName
            }

            Write-Host "    - Managed by: $nestedManagerName"
        }
    }
} else {
    Write-Host "No security group found with the specified extensionAttribute11 value."
}
