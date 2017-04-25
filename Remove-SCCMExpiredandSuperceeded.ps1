<#
    .Synopsis
        Loops thru the Software update groups and removes the expired and superceeded updates from the update group and deployment package

    .Description
        Part of the patching lifecycle is to perform maintenance to cleanup expired and superceeded patches.  This reduces storage requirements and cpu resources required.  This script will
        remove the updates from the software update group and the deployment package thus removing the files from the SCCM deployment point.
#>

[CmdletBinding()]
Param()

import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:

$VerbosePreference = 'Continue'

Get-CMSoftwareUpdateGroup | Foreach {
    
    $SUGName = $_.LocalizedDisplayName

    Write-Verbose "Checking $SUGName"

    Get-CMSoftwareUpdate -UpdateGroupName $SUGName -Fast | where { $_.issuperseded -or $_.IsExpired } | Foreach {

        Remove-SCCMSoftwareUpdateFromGroup -SoftwareUpdate $_ -softwareUpdateGroupName $SUGName 
        Remove-SCCMSoftwareUpdateFromDeploymentPackage -SoftwareUpdate $_ -DeploymentPackage $SUGName -verbose

    }
}