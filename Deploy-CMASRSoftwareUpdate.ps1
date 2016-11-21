<#
    .Description
        copies the patches downloaded via ADR to yearly software update group.  Then deploys the update group.

    .Note
        Author: Jeff Buenting
        Date: 28 Jul 2015
#>

$Year = Get-Date -UFormat %Y

$SoftwareUpdateGroup = "$Year - Patches"
$Collection = "Deploy Patches"

import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:
        
# ----- "If Software Update Group does not exist, Create it.  This is needed for year changes."
if ( (Get-CMSoftwareUpdateGroup -Name $SoftwareUpdateGroup) -eq $Null ) {
    New-CMSoftwareUpdateGroup -Name $SoftwareUpdateGroup
}

# ----- Copy patches from ADR SUG to Year SUG
Get-CMSoftwareUpdate -UpdateGroupName 'Patches' | Add-CMSoftwareUpdateToGroup -softwareUpdateGroupName $SoftwareUpdateGroup

# ----- This check is required as deploying with same name will have duplicate deployments
$ExistingDeployment = Get-CMDeployment -CollectionName $Collection | where SoftwareName -eq $SoftwareUpdateGroup

if ( $ExistingDeployment ) {
    # ----- Write-Verbose "Deployment $($ExistingDeployment.SoftwareName) Found for collection $Collection"
    $ExistingDeployment | Remove-CMDeployment -Force
}

# ----- Deploy Software update
Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $SoftwareUpdateGroup -CollectionName $Collection -DeploymentName "Patching" -DeploymentType Required -EnforcementDeadlineDay (get-date -UFormat '%Y/%m/%d')