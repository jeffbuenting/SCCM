Function Set-CMDeployment {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [PSCustomObject[]]$Deployment,



        [DateTime]$EnforcementDeadline
    )

    Begin {
        Write-Verbose "Getting Site Info"
        $Site = Get-CMSite

        [String]$NewDeadline = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($EnforcementDeadline)
        write-verbose $NewDeadline
    }

   Process {
        Foreach ( $D in $Deployment ) {
            Write-Verbose "Setting Deployment for $($D.SoftwareName)"

            # ----- Get the Deployment from Site Servers WMI
            $DeploymentInfo = Get-WmiObject -ComputerName $Site.ServerName -Namespace  "ROOT\SMS\site_$($Site.SiteCode)" -Query "SELECT * FROM SMS_DeploymentSummary WHERE SoftwareName='$($D.SoftwareName)' and collectionname='$($D.CollectionName)'"
            
            Write-Verbose "     Processing deployment $($DeploymentInfo.SOftwareName) for collection $($DeploymentInfo.CollectionName)"
        
            # ----- Set Enforcement Deadline if EnforcementDeadline is not Null
            if ( $EnforcementDeadline -ne $Null ) {
                Write-Verbose "          Changing EnforcementDeadline from $($DeploymentInfo.EnforcementDeadline) to $EnforcementDeadline"
                $DeploymentInfo.EnforcementDeadline = $NewDeadLine 
            }
            
            #Set-CIMInstance -Inputobject $DeploymentInfo            
            $DeploymentInfo.Put('EnforcementDeadline')
        }
    }
}


get-cmdeployment | where softwarename -eq '2015 - Patches'  | Set-CMDeployment -EnforcementDeadline (get-date).DateTime -verbose