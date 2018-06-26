# ---------------------------------------------------------------------------------
# Client Cmdlets
#----------------------------------------------------------------------------------

Function Start-CMClientAction {
<#
    .Synopsis
        Initiates an SCCM action on the remote client

    .Description
        Initiates an SCCM action on the remote client
    

    .Parameter ComputerName
        Name of the remote client to run action against.

    .Parameter Action
        Action to run on the remote client

    .Link
        http://www.configmgr.no/2012/01/17/trigger-sccm-client-action-from-powershell/

        List of action IDs
        http://www.moyerteam.com/2012/11/powershell-trigger-configmgr-client-action-scheduleid/
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline = $True)]
        [String[]]$ComputerName,

        [Parameter(Mandatory=$True)]
        [ValidateSet( 'HardwareInventory','SoftwareInventory','Discovery','MachinePolicy','FileCollection','SoftwareMetering','WinInstallerSourceList','SoftwareUpdateScan','SoftwareUpdateStore','SoftwareUpdateDeployment' )]
        [String]$Action
    )

    Process {
        Write-Verbose "ComputerName = $($ComputerName | out-string)"
     
        Foreach ( $C in $ComputerName ) {
            
            Write-Verbose "Running on $C"

            $SMSClient = Get-WMIObject -ComputerName $C -Namespace "root\ccm" -Class SMS_Client -list

            write-Verbose "----"
            Write-Verbose $($SMSClient | out-string)
            write-Verbose "----"

            Switch ( $Action ) {
                'HardwareInventory' { 
                    Write-Verbose "     Running HardWare Inventory"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000001}') | Out-Null
                }
                'SoftwareInventory' { 
                    Write-Verbose "     Running Software Inventory"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000002}') | Out-Null
                }
                'Discovery' { 
                    Write-Verbose "     Running Discovery Data Record"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000003}') | Out-Null
                }
                'MachinePolicy' { 
                    Write-Verbose "     Running Machine Policy"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000021}') | Out-Null
                }
                'FileCollection' { 
                    Write-Verbose "     Running File Collection"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000010}') | Out-Null
                }
                'SoftwareMetering' { 
                    Write-Verbose "     Running Software Metering"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000022}') | Out-Null
                }
                'WinInstallerSourceList' { 
                    Write-Verbose "     Running Windows Installer Source List"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000032}') | Out-Null
                }
                'SoftwareupdateScan' { 
                    Write-Verbose "     Running Software Update Scan"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000113}') | Out-Null
                }
                'SoftwareupdateStore' { 
                    Write-Verbose "     Running Software Update Store"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000114}') | Out-Null
                }
                'SoftwareupdateDeployment' { 
                    Write-Verbose "     Running Software Update Deployment"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000108}') | Out-Null
                }
            }
        }
    }
}

# --------------------------------------------------------------------------------
# Collection Cmdlets
# --------------------------------------------------------------------------------

Function Get-CMDeviceCollectionMember {

<#
    .Discovery
        Retieves the Members in an SCCM Device Collection.

    .Parameter DeviceCollection
        Device collection object.  You can use Get-CMDeviceCollection to get object.

#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [PSCustomObject[]]$DeviceCollection 
    )
    
    Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite
    }

    Process {
        Foreach ( $Coll in $DeviceCollection ) {
            Write-verbose "Retriveing members for Collection $COll"
            Get-CimInstance -ComputerName $Site.ServerName -Namespace  "ROOT\SMS\site_$($Site.SiteCode)" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($Coll.CollectionID)'" | Write-Output
        }
    }
}

#----------------------------------------------------------------------------------
# Compliance Cmdlets
# ---------------------------------------------------------------------------------

Function Set-CMBaselineFromSUG {

<#
    .Description 
        Assigns Updates from a Software Updtate Group to a Configuration Baseline

    .Link
        http://thedesktopteam.com/blog/raphael/sccm-2012-r2-sw-update-group-to-baseline/

#>

    [CmdletBinding()]
    Param (
        [String]$SiteCode,

        [String]$Name,

        [String]$SoftwareUpdateGroup
    )

    Begin {
        # ----- Load the SCCM module if not already loaded
        if ( -Not (Get-module -Name ConfigurationManager ) ) {
            Write-Verbose 'Importing SCCM Module as it is not already installed'
            $SCCMModuleInstalled = $False
            $Location = $PWD
            import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
        }

        Set-Location "$($SiteCode):"

        $SCCMSite = Get-CMSite -SiteCode $SiteCode

        if ( ( $Baseline = Get-CMBaseline -Name $Name ) -eq $Null ) {
                Write-Verbose "New Baseline"
                #$Updates =  Get-CMSoftwareUpdate -UpdateGroupName $SoftwareUpdateGroup | Select-Object -First 1
                #$ScopeID = $updates.ModelName.Substring(0,$updates.ModelName.IndexOf("/")) -replace "Site_", "ScopeID_"
		        #$BaselineLogicalName = "Baseline_" + [guid]::NewGuid().ToString()
		        #$BaselineVersion = 1
                $Baseline = New-CMBaseline -Name $Name
                $BaselineCI_ID = $Baseline.CI_ID 
		        $BaselineCI_UniqueID = $Baseline.CI_UniqueID
		        $ScopeID = $BaselineCI_UniqueID.substring(0,$BaselineCI_UniqueID.indexof("/"))
		        $BaselineLogicalName = $baseline.CI_UniqueID.substring($baseline.CI_UniqueID.indexof("/")+1)
		        $BaselineVersion = $Baseline.SDMPackageVersion + 1

		        Write-Host "Querying CI information..."
		        $CI = gwmi -computername $SCCMSite.ServerName -Namespace "root\sms\site_$SiteCode" -query "SELECT * FROM SMS_ConfigurationItem where CI_ID = $BaselineCI_ID"
		        if ($CI -eq $null) {
			        Write-Host "CI $BaselineCI_ID does not exist, no action taken" -ForegroundColor red
			        Exit
		        }

            }
            else {
                Write-Verbose "Existing Baseline"
                if ((Read-Host "Baseline $SUPGroupName already exist, do you want to replace it? (Y/N)").Tolower() -eq "n") {
			        Write-Host "Cancelled by the user, no action taken..." -ForegroundColor Red
			        exit
		        }
               
                $BaselineCI_ID = $Baseline.CI_ID 
		        $BaselineCI_UniqueID = $Baseline.CI_UniqueID
		        $ScopeID = $BaselineCI_UniqueID.substring(0,$BaselineCI_UniqueID.indexof("/"))
		        $BaselineLogicalName = $baseline.CI_UniqueID.substring($baseline.CI_UniqueID.indexof("/")+1)
		        $BaselineVersion = $Baseline.SDMPackageVersion + 1

		        Write-Host "Querying CI information..."
		        $CI = gwmi -computername $SCCMSite.ServerName -Namespace "root\sms\site_$SiteCode" -query "SELECT * FROM SMS_ConfigurationItem where CI_ID = $BaselineCI_ID"
		        if ($CI -eq $null) {
			        Write-Host "CI $BaselineCI_ID does not exist, no action taken" -ForegroundColor red
			        Exit
		        }
                
        }

    }

    Process {
        Write-Verbose "Creating Baseline XML Definition file"
        $baselineXML = @"
<?xml version="1.0" encoding="utf-16"?>
<DesiredConfigurationDigest xmlns="http://schemas.microsoft.com/SystemsCenterConfigurationManager/2009/07/10/DesiredConfiguration">
  <!--Authored against the following schema version: 5-->
  <Baseline AuthoringScopeId="$ScopeID" LogicalName="$BaselineLogicalName" Version="$BaselineVersion">
    <Annotation xmlns="http://schemas.microsoft.com/SystemsCenterConfigurationManager/2009/06/14/Rules">
      <DisplayName Text="$BaselineName" />
      <Description Text="" />
    </Annotation>
    <RequiredItems />
    <ProhibitedItems />
    <OptionalItems />
    <OperatingSystems />
    <SoftwareUpdates>
"@

        Write-Verbose "Software Update Group = $SoftwareUpdateGroup"
            
        Get-CMSoftwareUpdate -UpdateGroupName $SoftwareUpdateGroup | foreach {
            Write-Verbose "Adding Updates to new Baseline: ModelID = $($_.ModelID)"

            $Str = $_.ModelName -split '/'
            $ModelName = $Str[0]
            $LogicalName = $Str[1]
            #$ModelName = $Upd.ModelName.Substring(0,$updates[0].ModelName.IndexOf("/"))
		    #  $LogicalName = $Upd.ModelName.Substring($updates[0].ModelName.IndexOf("/")+1)
		    $baselineXML += @"
      <SoftwareUpdateBundleReference AuthoringScopeId="$ModelName" LogicalName="$LogicalName" />
"@
        }
            
        $baselineXML += @"
    </SoftwareUpdates>
    <Baselines />
    <OtherConfigurationItems />
  </Baseline>
</DesiredConfigurationDigest>
"@
    Write-Verbose "Preparing to write Baseline..."
	if ($Baseline -eq $null) {
#		$CI_class = [wmiclass]""
#		$CI_class.psbase.Path = "\\$($Site.Server)\ROOT\SMS\site_$($SiteCode):SMS_ConfigurationItem"
#		$CI = $CI_class.createInstance()
#		
#		$LD_class = [wmiclass]""
#		$LD_class.psbase.Path = "\\$($Site.Server)\ROOT\SMS\site_$($SiteCode):SMS_SDMPackageLocalizedData"
#		$LD = $LD_class.createInstance()
#		$LD.LocaleID = 1033
#		$LD.LocalizedData = $resxml
#		$CI.SDMPackageLocalizedData += $LD
#
#		$CI.IsBundle = $false
#		$CI.IsExpired = $false
#		$CI.IsUserDefined = $true
#
#		$CI.ModelID = 16777367
#		$CI.PermittedUses = 0
#		$CI.PlatformCategoryInstance_UniqueIDs = "Platform:C92857DF-9FD1-4FAD-BAA1-BE9FAD4B4F74"

                $Baseline = New-CMBaseline -Name $Name
                $BaselineCI_ID = $Baseline.CI_ID 
		        $BaselineCI_UniqueID = $Baseline.CI_UniqueID
		        $ScopeID = $BaselineCI_UniqueID.substring(0,$BaselineCI_UniqueID.indexof("/"))
		        $BaselineLogicalName = $baseline.CI_UniqueID.substring($baseline.CI_UniqueID.indexof("/")+1)
		        $BaselineVersion = $Baseline.SDMPackageVersion + 1

		        Write-Host "Querying CI information..."
		        $CI = gwmi -computername $SCCMSite.ServerName -Namespace "root\sms\site_$SiteCode" -query "SELECT * FROM SMS_ConfigurationItem where CI_ID = $BaselineCI_ID"
		        if ($CI -eq $null) {
			        Write-Host "CI $BaselineCI_ID does not exist, no action taken" -ForegroundColor red
			        Exit
		        }




	}
	
	$CI.SDMPackageXML = $baselineXML
	
	if ($Baseline -eq $null) { Write-Host "Creating baseline..." } else {Write-Host "Updating baseline..." }
	$CI.Put() | Out-Null
	if ($Baseline -eq $null) { Write-Host "Baseline $SUPGroupName create successfully..." } else { Write-Host "Baseline $SUPGroupName updated successfully..." }

}

    End {
        if ( $SCCMModuleInstalled ) {
            # ----- Cleanup
            Write-Verbose 'Removing SCCM Module'
            Set-Location -Path $Location
            Remove-Module ConfigurationManager
        }
    }
}

#----------------------------------------------------------------------------------
# SCCM Software Update Cmdlets
#----------------------------------------------------------------------------------

Function Get-SCCMSoftwareUpdate {

<#
    .Description
        Gets SCCM Software Update Informatlion

    .Parameter ArticleID
        Software Update Article ID.

    .Note
        This is actually different from the built in Get-CMSoftwareUpdate.  The data retrieved is different.
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String[]]$ArticleID
    )

    Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite
    }

    Process {
        If ( [String]::IsNullOrEmpty($ArticleID) ) {
                Write-Verbose "Returning all Updates"
                Write-Output (Get-CIMInstance -ComputerName $Site.ServerName -Namespace "root\sms\site_$($Site.SiteCode)" -Class 'SMS_SoftwareUpdate' )
            }
            ForEach ( $A in $ArticleID ) {
                Write-Verbose "Retrieving software update: $A"
                       
                Write-Output (Get-CIMInstance -ComputerName $Site.ServerName -Namespace "root\sms\site_$($Site.SiteCode)" -Class 'SMS_SoftwareUpdate' -Filter "ArticleID = $A")
            
        }
    }
}

#--------------------------------------------------------------------------------------

Function Get-SCCMSoftwareUpdateMemberof {

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True,ValueFromPipeline=$True )]
        [PSCustomObject[]]$SoftwareUpdate,

        [String[]]$SUG
    )

     Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite
    }

    Process {
        Foreach ( $SU in $SoftwareUpdate ) {
            Write-Verbose "Getting Member of infor for $($SU.CI_ID)"
            if ( [String]::IsNullOrEmpty( $SUG ) ) {
                    Write-Verbose "Checking all Membership"
                    $SUGList = Get-CMSoftwareUpdateGroup
                   
                    ForEach ( $S in $SUGList ) {
                        Write-Verbose "Checking $($S.LocalizedDisplayName)"
                        
                        if ( $SU.CI_ID -in $S.Updates ) {
                            Write-Output $S.LocalizedDisplayName
                        }
                    }
                }
                Else {
                    Write-Verbose "Checking Update is in the specified SUGs"
                    ForEach ( $S in $SUG ) {
                        if ( $SU.CI_ID -in (Get-CMSoftwareUpdateGroup -Name $S).Updates ) {
                            Write-OutPut $S
                        }
                    }
            }
            
        }
    }

}


#--------------------------------------------------------------------------------------

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

#--------------------------------------------------------------------------------------



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

    .Parameter Force
        Forces the removal of the software update from a Software Update Deployment Package. This does not remove membership from a Software Update Group.

    .Parameter Refresh
        including this switch will refresh the software update deployment package on the deployment point.  For efficiency sake it may be better to do a refresh after all changes have been made.

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
        [String]$DeploymentPackage,

        [Switch]$Force,

        [switch]$Refresh
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
                if ( $Force ) {
                    Write-Verbose "Force switch"
                
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
                Else {
                    Write-Warning "$($S.ArticleID) is a member of Software UpdateGroup(s):`n$($SUG | out-string)"
                    Write-Warning "Use the Force switch to force removal of the update from the Software Update Deployment Package"
                }
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
        if ( $Refresh ) {
            Write-Verbose "Refreshing distribution points for Software Update Group: $($DP.Name)"
            if ( ($DP.RefreshPkgSource()).ReturnValue -ne 0 ) {
                Throw "Remove-SCCMSoftwareUpdateFromDeploymentPackage : Error refreshing the deployment point for Software updatae group $($DP.Name)"
            }
        }
    }
}

#----------------------------------------------------------------------------------

Function Refresh-SCCMSoftwareUpdateDeploymentPackage {

<#
    .Synopsis
        Refreshes the Software Update Deployment Package on the distribution point

    .Description
        Refreshes the Software Update Deployment Package on the distribution point.  This Function was moved outside of the other Deployment Package functions because it speeds up the processes to not refresh during pipline input.

    .Parameter DeploymentPackageName
        Name of the Deployment Package to refresh.

    .Parameter SiteServer
        Name of the SCCM Site Server

    .Example
        Refreshes the test software update deployment package.

        Refresh-SCCMSoftwareUpdateDeploymentPackage -DeploymentPackageName Test

    .Note
        Author : Jeff Buenting
        Date : 2017 May 09
#>
    
    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True ) ]
        [String]$DeploymentPackageName,

        [String]$SiteServer = $env:COMPUTERNAME
    )

   
    Write-verbose "Determining Site Code for site server : $SiteServer"
    Try {
        $SiteCode = (Get-CIMInstance -Namespace "root\SMS" -Classname SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop).SiteCode
    }
    Catch {
        $EXceptionMessage = $_.Exception.Message
        $ExceptionType = $_.exception.GetType().fullname
        Throw "Refresh-SCCMSoftwareUpdateDeploymentPackage : Unable to determin the SiteCode for $SiteServer.`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"
    }
        
    Write-verbose "Getting Sotware Update Deployment Package $DeploymentPackage"
    Try {
        # ----- The built in cmdlet Get-CMSoftwareUpdateDeploymentPackage does not have a method to remove updates.  Using CIMInstance also does not return a usable method.  THerefor I must use the depricated get-WMIObject.
        $DeploymentPackage =  Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_SoftwareUpdatesPackage WHERE Name='$DeploymentPackageName'" -ErrorAction Stop
    }
    Catch {
        $EXceptionMessage = $_.Exception.Message
        $ExceptionType = $_.exception.GetType().fullname
        Throw "Refresh-SCCMSoftwareUpdateDeploymentPackage : Error getting Software Update Deployment Package $DeploymentPackageName`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"       
    }

    Write-Verbose "Refreshing distribution points for Software Update Group: $DeploymnentPackageName"
    if ( ($DeploymentPackage.RefreshPkgSource()).ReturnValue -ne 0 ) {
        Throw "Add-SCCMUpdateToDeploymentPackage : Error refreshing the deployment point for Software updatae group $DeploymentPackageName"
    }
}

#----------------------------------------------------------------------------------

Function Get-SCCMSoftwareUpdateDeploymentPackageUpdateSourcePath {

<#
    .Synopsis
        Returns the Source path of an update in a Deployment Package

    .Description
        Updates in a Software Update Deployment package have been downloaded to the the storage system.  This Function returns the path to that location.

    .Parameter SoftwareUpdate
        Software Update Object that is a member of the deploymen package

    .parameter DeploymentPackageName
        Name of the Software Update Deploymnet package that downloaded the Software Update.

    .Parameter SiteServer
        Name of the SCCM Site Server.  Defaults to the local computer.

    .Example
        Return the source path where patch 919678 has been downloaded

        Get-CMSoftwareUpdate -UpdateGroupName Patches -Fast | Get-SCCMSoftwareUpdateDeploymentPackageUpdateSourcePath -DeploymentPackageName Patches -Verbose

    .Notes
        Author : Jeff Buenting
        Date : 2017 May 02
#>

    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True, ValueFromPipeline = $True ) ]
        [PSObject[]]$SoftwareUpdate,

        [Parameter ( Mandatory = $True ) ]
        [String]$DeploymentPackageName,

        [String]$SiteServer = $env:COMPUTERNAME
    )

    Begin {
        Write-verbose "Determining Site Code for site server : $SiteServer"
        Try {
            $SiteCode = (Get-CIMInstance -Namespace "root\SMS" -Classname SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop).SiteCode
        }
        Catch {
            $EXceptionMessage = $_.Exception.Message
            $ExceptionType = $_.exception.GetType().fullname
            Throw "Add-SCCMUpdateToDeploymentPackage : Unable to determin the SiteCode for $SiteServer.`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"
        }
        
        Write-Verbose "Getting the DeploymentPackage object for $DeploymentPackageName"
        $DeploymentPackage = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_SoftwareUpdatesPackage WHERE Name='$DeploymentPackageName'"
    }

    Process {
        Foreach ( $S in $SoftwareUpdate ) {
            Write-Verbose "Retrieving the path for $($S.ArticleID) in $DeploymentPackageName"

            # ----- Get a the source file location for an Update in a Deployment Package
            $Update = Get-CIMInstance -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -query "SELECT SMS_PackageToContent.* From SMS_PackageToContent Join SMS_CIToContent ON SMS_CIToContent.ContentID=SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID = $($S.CI_ID) and SMS_PackageToCOntent.PackageID = '$($DeploymentPackage.PackageID)'" 
            foreach( $U in $Update ) {
                Write-Verbose "Update = $($U | out-String)"
                Write-Output (Get-childitem E:\Sources\UpdateServicesPackages\$DeploymentPackageName | where Name -eq $U.ContentSubFolder)
            } 
        }
    }
}

#----------------------------------------------------------------------------------

Function Add-SCCMUpdateToDeploymentPackage {

<#
    .Synopsis
        Adds a Software Update to a software update deployment package in SCCM

    .Description
        Sometimes you might want to move the software updates between software update Deployment packages.  Since the update has already been downloaded, this function will add it to a second deploymen package.

    .Parameter SoftwareUpdate
        This is an SCCM Software Update object to be added to the Deployment Package.

    .Parameter DeploymentPackageName
        Name of the deployment package that you are adding updates.     

    .Parameter SrcPath
        Path to the location where the update has been downloaded.  This should be the parent.  That way if there are multilple GUID Downloads associated with one patch, they will all be included with the upda

        This cannot be the same path as another Deployment Package.

    .Paramete SiteServer
        SCCM Site Server.

    .Parameter Refresh
        including this switch will refresh the software update deployment package on the deployment point.  For efficiency sake it may be better to do a refresh after all changes have been made.

    Example
        Gets a list of updates from a software Update Group.  "Downloads" the updates to a temporary location and adds them to the software update deploymnet package

        $Updates = Get-CMSoftwareUpdate -UpdateGroupName Patches -Fast

        foreach ( $U in $Updates ) {
    
            # ----- Copy the update from the the Deployment Package to a temporary location
            $Path = @()
            Get-SCCMSoftwareUpdateDeploymentPackageUpdateSourcePath -softwareUpdate $U -DeploymentPackageName Patches -ErrorAction Stop | Foreach {
                Try {
                    if ( -Not (Test-Path -Path "C:\temp\patch\$($_.Name) -ErrorAction Stop" ) ) { 
                        New-Item -Path "C:\temp\patch\$($_.Name)" -ItemType Directory -ErrorAction Stop | Out-Null
                    }
                    Write-Output "Copying"
                    Copy-Item -Path "$($_.FullName)\*.*" -Destination "C:\temp\patch\$($_.Name)\" -Recurse -erroraction Stop
                }
                Catch {
                    $EXceptionMessage = $_.Exception.Message
                    $ExceptionType = $_.exception.GetType().fullname
                    Throw "Error Copying patch to Temporary location. `n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"       
                }

                $Path += "C:\temp\patch\$($_.Name)\"
            }

            # ----- Add to Deployment Package    
           Add-SCCMUpdateToDeploymentPackage -SoftwareUpdate $U -DeploymentPackageName Test -SrcPath $Path -verbose

            # ----- Clean up Temp File
            Foreach ( $P in $Path ) { Remove-Item -Path $P -Recurse -Force }
        }

    .Links
        https://www.petervanderwoude.nl/post/add-update-content-to-a-deployment-package-via-powershell-in-configmgr-2012/

    .Notes
        Author : Jeff Buenting
        Date : 2017 MAY 08
#>

    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True, ValueFromPipeline = $True ) ]
        [PSObject[]]$SoftwareUpdate,

        [Parameter ( Mandatory = $True ) ]
        [String]$DeploymentPackageName,

        [String[]]$SrcPath = 'c:\temp',

        [String]$SiteServer = $env:COMPUTERNAME,

        [Switch]$Refresh
    )

    Begin {
        Write-verbose "Determining Site Code for site server : $SiteServer"
        Try {
            $SiteCode = (Get-CIMInstance -Namespace "root\SMS" -Classname SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop).SiteCode
        }
        Catch {
            $EXceptionMessage = $_.Exception.Message
            $ExceptionType = $_.exception.GetType().fullname
            Throw "Add-SCCMUpdateToDeploymentPackage : Unable to determin the SiteCode for $SiteServer.`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"
        }
        
        Write-Verbose "Getting the DeploymentPackage object for $DeploymentPackageName"
        $DeploymentPackage = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_SoftwareUpdatesPackage WHERE Name='$DeploymentPackageName'"   
    }

    Process {
        
        Foreach ( $S in $SoftwareUpdate ) {

            Write-Verbose "Adding $($S.ArticleID) to $DeploymentPackageName"

            $ContentID = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_CIToContent where SMS_CIToContent.CI_ID='$($S.CI_ID)'" | Select-Object -ExpandProperty ContentID

            Write-Verbose "add"
            if ( ($DeploymentPackage.AddUpdateContent( $ContentID,$SrcPath,$False )).ReturnValue -ne 0 ) {
                Throw "Add-SCCMUpdateToDeploymentPackage : Error adding Software Update $($S.ArticleID) (ArticleID) to $DeploymentPackage"
            }
        }   
    }

    End {
        # ----- Refresh the software update package distribution point
        if ( $Refresh ) {
            Write-Verbose "Refreshing distribution points for Software Update Group: $DeploymnentPackageName"
            if ( ($DeploymentPackage.RefreshPkgSource()).ReturnValue -ne 0 ) {
                Throw "Add-SCCMUpdateToDeploymentPackage : Error refreshing the deployment point for Software updatae group $DeploymentPackageName"
            }
        }
    }
}

#----------------------------------------------------------------------------------
# SCCM Client Cmdlets
#----------------------------------------------------------------------------------

Function Clear-SCCMClientCache {

<#
    .Synopsis
        Clears the SCCM Client Cache

    .Description
        Updates and applications are downloaded to an SCCM Client to its cache ( C:\windows\CCMCache ) and then run from this location during the installs.  Unfortunately, SCCM does not clean up this cache efficiently and it can fill up.  This Cmdlet will clear the SCCM cache like the GUI commands.

    .Parameter Computername
        Name of the client whose cache you want to clear
        
    .Example
        Clear-SCCMClientCache -Computername ServerA

    .Link
        http://myitforum.com/myitforumwp/2011/11/10/how-to-properly-remove-items-from-configmgr-client-cache-using-powershell-and-vbscript/

    .Note
        Author : Jeff Buenting
        Date : 2016 NOV 21
#>


    [CmdletBinding()]
    param (
        [Parameter ( ValueFromPipeline = $True ) ]
        [String[]]$ComputerName = $env:COMPUTERNAME  
    )


    Process {
        Foreach ( $C in $ComputerName ) {
            Write-Verbose "Clearing the SCCM Cache on $C "
            invoke-Command -ComputerName $C -ScriptBlock {
                #Connect to Resource Manager COM Object
                $resman = new-object -com "UIResource.UIResourceMgr"
                $cacheInfo = $resman.GetCacheInfo()
                #Enum Cache elements, compare date, and delete older than 60 days
                $cacheinfo.GetCacheElements() | Foreach {
                    $cacheInfo.DeleteCacheElement($_.CacheElementID)
                }
            }
        }
    }
}

#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------