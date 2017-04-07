function Remove-SCCMSoftwareUpdateFromDeploymentPackage {

<#
    .Synopsis
        Removes a software update from a Software Update Deployment Package

    .Description
        If a software update is no longer a member of a Software Update Group, it should be removed from any Software update deployment packages.  This will remove it from the SCCM Deployment Point thus freeing up disk space.

    .Parameter SoftwareUpdate
        Software update to remove from the Deployment Package.

    .Parameter DeploymentPackage
        Deployment Package name.

    
#>

    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True, ValueFromPipeline = $True ) ]
        [String[]]$SoftwareUpdate,

        [Parameter ( Mandatory = $True ) ]
        [String]$DeploymentPackage
    )

    Begin {
        Write-verbose "Getting Sotware Update Deployment Package"
        $DP = Get-CMSoftwareUpdateDeploymentPackage -Name $DeploymentPackage
    }

    Process {
        Write-Verbose "Removing the following updates from $DeploymentPackage"
        Foreach ( $S in $SoftwareUpdate ) {
            Write-Verbose $S

        }
    }
}
