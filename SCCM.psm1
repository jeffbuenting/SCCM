# ---------------------------------------------------------------------------------
# Client Cmdlets
#----------------------------------------------------------------------------------

Function Start-CMClientAction {

<#
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
        Foreach ( $C in $ComputerName ) {
            Write-Verbose "Running $Action on $C"
            $SMSClient = Get-WmiObject -ComputerName $C -Namespace "root\ccm" -ClassName SMS_Client -list
            
            Switch ( $Action ) {
                'HardwareInventory' { 
                    Write-Verbose "     Running HardWare Inventory"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000001}') 
                }
                'SoftwareInventory' { 
                    Write-Verbose "     Running Software Inventory"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000002}') 
                }
                'Discovery' { 
                    Write-Verbose "     Running Discovery Data Record"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000003}') 
                }
                'MachinePolicy' { 
                    Write-Verbose "     Running Machine Policy"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000021}') 
                }
                'FileCollection' { 
                    Write-Verbose "     Running File Collection"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000010}') 
                }
                'SoftwareMetering' { 
                    Write-Verbose "     Running Software Metering"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000022}') 
                }
                'WinInstallerSourceList' { 
                    Write-Verbose "     Running Windows Installer Source List"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000032}') 
                }
                'SoftwareupdateScan' { 
                    Write-Verbose "     Running Software Update Scan"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000113}') 
                }
                'SoftwareupdateStore' { 
                    Write-Verbose "     Running Software Update Store"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000114}') 
                }
                'SoftwareupdateDeployment' { 
                    Write-Verbose "     Running Software Update Deployment"
                    $SMSClient.TriggerSchedule('{00000000-0000-0000-0000-000000000108}') 
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

Function Remove-SCCMSoftwareUpdateFromGroup {

    [CmdletBinding()]
    Param (
        
        [String[]]$SUG
    )

     Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite
    }

    Process {
        Foreach ( $S in $SUG ) {
            Write-verbose "Removing updates From Software Update Group $SUG"

            $AuthorizationList = Get-WmiObject -Namespace "root\SMS\site_$($Site.SiteCode)" -Class SMS_AuthorizationList -ComputerName $Site.Servername -Filter "LocalizedDisplayName like '$SUG'" -ErrorAction Stop
            $AuthorizationList = [wmi]"$($AuthorizationList.__PATH)"

            foreach ($Update in ($AuthorizationList.Updates)) {
                $CI_ID = Get-WmiObject -Namespace "root\SMS\site_$($Site.SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $Site.ServerName -Filter "CI_ID = '$($Update)'" -ErrorAction Stop 
                if (($CI_ID.IsExpired -eq $True) -or ($CI_ID.IsSuperseded -eq $True)) {
                    Write-Verbose "Found Expired/Superseded Update: $($CI_ID.CI_ID)"
               }
            }
                
        }
    }
}

#--------------------------------------------------------------------------------------

Function Remove-SCCMExpiredUpdates {

<#
    .Description
        Removes expired or superseded updates from an SCCM Software Update Group

    .Link
        http://gosc.nl/blog/technology/sccm/configmgr-2012-r2-script-remove-expired-updates-software-update-groups/

#>

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True,ValueFromPipeline=$True )]
        [PSCustomObject[]]$SUG,

        [Switch]$PassThru
    )

     Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite
       
        
    }

    Process {
        ForEach ( $S in $SUG ) {
             Write-Verbose " Removing Expired updates from $($S.LocalizedDisplayname)"

            # ----- Becaue I want to use the set-CIMInstance to save and update the SCCM Software update group ( As I haven't figured out a way to to it anyother way) I need to get the CIM instance of the SUG
            $SUGWMI = Get-CimInstance -computername $Site.ServerName -Namespace "root\sms\site_$($Site.SiteCode)" -query "SELECT * FROM SMS_AuthorizationList" | where LocalizedDisplayName -eq $S.LocalizedDisplayName

        
            # ----- Return Updates that are not expired or superseded from Software update groups and add it to the SUG      
            $Updates = gwmi -computername $Site.ServerName -Namespace "root\sms\site_$($Site.SiteCode)" -query "SELECT SU.* FROM SMS_SoftwareUpdate SU, SMS_CIRelation CIRelation WHERE CIRelation.FromCIID=$($S.CI_ID) AND CIRelation.RelationType=1 AND SU.CI_ID=CIRelation.ToCIID" | where { ($_.IsExpired -eq $False) -or ($_.IsSuperseded -eq $False) } | Select-object -ExpandProperty CI_ID 
                   
            $SUGWMI.Updates = $Updates
          

            Write-Verbose "Saving SUG"
            Set-CimInstance -InputObject $SUGWMI -PassThru
            #$SugWMI 

            if ( $PassThru ) {
                Write-Verbose "Returning New Software Update Group Object"
                Write-Output (Get-CMSoftwareUpdateGroup -Name $S.LocalizedDisplayName)
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