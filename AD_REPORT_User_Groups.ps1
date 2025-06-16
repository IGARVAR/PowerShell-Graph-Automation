<#
.SYNOPSIS
Retrieves all AD groups a user belongs to and optionally displays group ownership information.

.DESCRIPTION
This script prompts for a user's display name, finds their AD account, and retrieves all group memberships.
It also displays if the user is the owner of any group and can optionally show the actual group's owner (user or group).

.NOTES
Author: Ivan Garkusha
Filename: AD_REPORT_User_Groups.ps1

REQUIREMENTS:
- Active Directory PowerShell module
- Read access to AD users and groups

USAGE:
- Run the script and enter the user's DisplayName when prompted
- Enter 'yes' to also display the ManagedBy owner of each group
- Group names are color-coded by prefix if running in console (optional)
#>

# Import the AD module
Import-Module ActiveDirectory

function Get-UserGroupMembership {
    param (
        [string]$DisplayName,
        [bool]$ShowOwnerNames
    )

    # Find the user by display name
    $user = Get-ADUser -Filter "DisplayName -eq '$DisplayName'" -Properties MemberOf, ManagedBy

    if (-not $user) {
        Write-Host "User not found"
        return
    }

    if (-not $user.MemberOf) {
        Write-Host "User is not a member of any groups"
        return
    }

    # Define group prefix color logic (for terminal use)
    $colorMap = @{
        "RES*"   = "Green"
        "ROLE*"  = "Cyan"
        "DROLE*" = "Magenta"
    }

    Write-Host "Groups for user: $DisplayName"

    # Fetch full group objects and sort
    $sortedGroups = $user.MemberOf | ForEach-Object {
        Get-ADGroup -Identity $_ -Properties ManagedBy
    } | Sort-Object Name

    foreach ($group in $sortedGroups) {
        # Default color
        $color = "White"
        foreach ($prefix in $colorMap.Keys) {
            if ($group.Name -like $prefix) {
                $color = $colorMap[$prefix]
                break
            }
        }

        # Determine if the user is the group's owner
        $isOwner = $user.DistinguishedName -eq $group.ManagedBy
        $label = if ($isOwner) { "$($group.Name) (Owner)" } else { $group.Name }

        # Output group name
        Write-Host $label -ForegroundColor $color

        # If enabled, show actual owner of the group
        if ($ShowOwnerNames -and $group.ManagedBy) {
            try {
                $owner = Get-ADObject -Identity $group.ManagedBy -Properties DisplayName, ObjectClass
                if ($owner.ObjectClass -eq 'user') {
                    Write-Host "    Managed by: $($owner.DisplayName)" -ForegroundColor Yellow
                } elseif ($owner.ObjectClass -eq 'group') {
                    Write-Host "    Managed by group: $($owner.DisplayName)" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "    Managed by: (Unable to retrieve owner)" -ForegroundColor Yellow
            }
        }
    }
}

# Prompt user input
$displayName = Read-Host -Prompt "Enter the user's display name"
$showOwnerNames = Read-Host -Prompt "Show owner names? (yes/no)"
$showOwnerNames = $showOwnerNames -eq 'yes'

# Execute main logic
Get-UserGroupMembership -DisplayName $displayName -ShowOwnerNames $showOwnerNames
