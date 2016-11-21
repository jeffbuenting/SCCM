Function Start-CMASRPatchesDeployment {

    [CmdletBinding()]
    Param (
        [String]$DeployPatchesCollection
    )

    Process {
        $Year = Get-Date -UFormat %Y
        
        Write-Verbose "If Software Update Group does not exist, Create it.  This is needed for year changes."
        if ( (Get-CMSoftwareUpdateGroup -Name "$Year - Patches") -eq $Null ) {
            New-CMSoftwareUpdateGroup -Name "$Year - Patches"
        }

        # ----- Copy patches from ADR SUG to Year SUG
        Get-CMSoftwareUpdate -Name $Patches | Add-CMSoftwareUpdateToGroup -softwareUpdateGroupName "$Year - Patches"

        Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName "$Year - Patches" -CollectionName $DeployPatchesCollection -DeploymentName "ADR Patch Deployment" -DeploymentType Required 

    }
}


import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Import-Module C:\Scripts\SCCM\SCCM_Module.psm1 -force

set-location RWV:

Start-CMASRPatchesDeployment -DeployPatchesCollection '@ - Empty Collection' -verbose

