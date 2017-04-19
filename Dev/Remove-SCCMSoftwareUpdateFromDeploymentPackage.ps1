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

    .Example
        Remove a software update from a software update deployment Package.

        Get-CMSoftwareUpdate - ID 1692243 -Fast | Remove-SCCMSoftwareUpdateFromDeploymentPackage -DeploymentPacage "test"

    .Example
        Remove all expired and superceeded patches from a software update group and Software Update Deployment Package.

        $SUGName = '2012 - Patches'
        Get-CMSoftwareUpdate -UpdateGroupName $SUGName -Fast | where { $_.issuperseded -or $_.IsExpired } | Foreach {
            Remove-SCCMSoftwareUpdateFromGroup -SoftwareUpdate $_ -softwareUpdateGroupName $SUGName 
            Remove-SCCMSoftwareUpdateFromDeploymentPackage -SoftwareUpdate $_ -DeploymentPackage $SUGName -verbose
        }

    .Link
        Used alot of code from Trevou Sullivan. So a big thank you to him.  I did modify it so it will work for any update passed not just delete expired and superceeded.

        https://trevorsullivan.net/2011/11/29/configmgr-cleanup-software-updates-objects/

    .Notes
        Author : Jeff Buenting
        Date : 2017 APR 19
    
#>

    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True, ValueFromPipeline = $True ) ]
        [PSObject[]]$SoftwareUpdate,

        [Parameter ( Mandatory = $True ) ]
        [String]$DeploymentPackage
    )

    Begin {
        Write-verbose "Getting Sotware Update Deployment Package $DeploymentPackage"
        Try {
            # ----- The built in cmdlet Get-CMSoftwareUpdateDeploymentPackage does not have a method to remove updates.  Using CIMInstance also does not return a usable method.  THerefor I must use the depricated get-WMIObject.
            $DP =  gwmi -Class sms_softwareupdatespackage -Namespace root\sms\site_rwv -filter "Name = '$DeploymentPackage'" -ErrorAction Stop
        }
        Catch {
            $EXceptionMessage = $_.Exception.Message
            $ExceptionType = $_.exception.GetType().fullname
            Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error getting Software Update Deployment Package $DeploymentPackage`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"       
        }
    }

    Process {    
        Write-Verbose "Removing the following updates from $DeploymentPackage"
        Foreach ( $S in $SoftwareUpdate ) {
            # ----- If the update is a member of a software update group and not a member of another Deployment package then we can't remove the update until it does not belong to a group
            Write-Verbose "Check if the update is a member of a software update group"

            Try {
                $SUG = $S | Get-SCCMSoftwareUpdateMemberof -ErrorAction Stop
            }
            Catch {
                $EXceptionMessage = $_.Exception.Message
                $ExceptionType = $_.exception.GetType().fullname
                Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error Checking if Update is a member of a Software Update Group`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"       
            } 

            if ( $SUG ) {
                Write-Warning "$($S.ArticleID) is a member of Software UpdateGroup(s):`n$($SUG | out-string)"
                Write-Warning "Not sure if I want to have a force switch included so that the update is removed from the Software Update Groups"
            }
            else {
                Write-Verbose "$($S.ArticleID) is not a member of a software update group."
                
                # ----- Convert Software update ID to Package Content ID.
                # Software packages are a little bit different from the other software updates objects. This is how the various objects relate:
                # SMS_SoftwareUpdate <-> SMS_CiToContent <-> SMS_PackageToContent <-> SMS_SoftwareUpdatesPackage

                Try {
                    $Update = Get-CIMInstance -ComputerName rwva-sccm -Namespace "root\sms\site_rwv" -query "SELECT SMS_PackageToContent.* From SMS_PackageToContent Join SMS_CIToContent ON SMS_CIToContent.ContentID=SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID = $($S.CI_ID) and SMS_PackageToCOntent.PackageID = '$($DP.PackageID)'" -ErrorAction Stop
                }
                Catch {
                    $EXceptionMessage = $_.Exception.Message
                    $ExceptionType = $_.exception.GetType().fullname
                    Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error converting Software Update CI_ID to Package Content ID $DeploymentPackage`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"       
                }

                if ( $Update ) {
                    $Update.contentid

                    # ----- Remove from software update package
                    if ( ($DP.RemoveContent( $Update.ContentID,$False )).ReturnValue -ne 0 ) {
                        Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error Removing $($S.ArticleID) from $($DP.Name)"
                    }
                }
                Else {
                    Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : $($S.ArticleID) does not exist in Software Update Group $($DP.Name)"
                }
            }     
        }
    }

    End {
        # ----- Refresh the software update package distribution point
        Write-Verbose "Refreshing distribution points for Software Update Group: $($DP.Name)"
        if ( ($DP.RefreshPkgSource()).ReturnValue -ne 0 ) {
            Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error refreshing the deployment point for Software updatae group $($DP.Name)"
        }
    }
}