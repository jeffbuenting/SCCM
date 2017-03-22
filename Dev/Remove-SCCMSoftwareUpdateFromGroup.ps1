function Remove-SCCMSoftwareUpdateFromGroup {

<#
    .Synopsis
        Removes a Software update from a Software update group and deployment package.

    .Description
        Removes a Software update from a Software update group and deployment package.

    .Parameter SoftwareUpdate
        Update object that we want to remove.  use Get-CMSoftwareUpdate.

    .Parameter SoftwareUpdageGroupname

    .Example
        Remove the expired or superceeded updates from a Software Update Group

        Get-CMSoftwareUpdate -UpdateGroupName test -Fast | where { $_.issuperseded -or $_.IsExpired } | Remove-sccmSoftwareUpdateFromGroup -verbose

    .Notes
        Author : Jeff Buenting
        Date : 2017 MAR 22
#>

    [CmdletBinding()]
    Param (        
        [Parameter ( Mandatory = $True, ValuefromPipeline = $True ) ]
        [PSObject[]]$SoftwareUpdate,

        [String]$softwareUpdateGroupName
    )

    Begin {
        Write-Verbose "Getting Softwareupdate Group"
        $UpdateList = @()
        $SUGNames = @()

        if ( $SoftwareUpdateGroupname ) {
            Foreach ( $N in $SoftwareUpdateGroupName ) {
                $SUG = Get-CMSOftwareUpdateGroup -Name $N
            }
        }
        Else {
            Write-Verbose "Getting all SOftware update Groups"
           
            $SUG = Get-CMSoftwareUpdateGroup
        }

        $UpdateList = @()
    }

    Process {
        Foreach ( $S in $SoftwareUpdate ) {
            Write-verbose "Removing $($S.CI_ID)"
            
            # ----- Process each Software update Group
            Foreach ( $G in $SUG ) {
                Write-verbose "Checking Software Update Group $($G.LocalizedDisplayname)"
                Write-Verbose "Current Update Count = $($G.Updates.count)"

                $UpdateList = @()

                foreach ( $U in $G.Updates ) {
                    if ( $U -ne $S.CI_ID ) {
                        $UpdateList += $U
                    }
                }

                $G.Updates = $UpdateList

                Write-Verbose "Update count after removing listed update = $($G.Updates.count)"
            }
        }
    }

    End {
        Foreach ( $G in $SUG ) {
            Write-Verbose "Saving Updated SoftwareUpdate : $($G.LocalizedDisplayName)"
            
            $G.Put()
        }
    }
}

#Get-CMSoftwareUpdate -UpdateGroupName test -Fast | where { $_.issuperseded -or $_.IsExpired } #| Remove-sccmSoftwareUpdateFromGroup -verbose
