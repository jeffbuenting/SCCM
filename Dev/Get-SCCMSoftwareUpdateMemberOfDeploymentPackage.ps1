function Get-SCCMSoftwareUpdateMemberOfDeploymentPackage {

<#
    .Synopsis
        Retrieves a list of Software Update Deployment Packages that the Software Update is a member of.

    .Description
        Retrieves a list of Software Update Deployment Packages that the Software Update is a member of.

    .parameter Package
        Sotware Update Deployment Package object.  Use Get-CMSoftwareDeploymentPackage.

    .Parameter SiteServer
        SCCM Site Server name.

    .Examples
        Get a list of all Software updates in the Software Update Deployment Package Test

        Get-SCCMSoftwareUpdateMemberOfDeploymentPackage -Package (Get-CMSoftwareUpdateDeploymentPackage -Name Test)

    .Links
        Got alot of info from this script on how to do this.  I had to figure out the Join but this was where I started so a big thanks to Nickolaj.

        https://gallery.technet.microsoft.com/scriptcenter/Remove-Expired-Superseded-f35495e1

    .Input

    .Output

    .Notes
        Author : Jeff Buenting
        Date : 2017 MAR 31
        
#>

    [CmdletBinding()]
    Param (
        [Parameter ( Mandatory = $True,ValueFromPipeline = $True ) ]
        [PSObject[]]$Package,

        [String]$SiteServer = $env:COMPUTERNAME
    )

    Begin {
        Write-verbose "Determining Site Code for site server :$SiteServer"
        Try {
            Get-CIMInstance -Namespace "root\SMS" -Classname SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        }
        Catch {
            $EXceptionMessage = $_.Exception.Message
            $ExceptionType = $_.exception.GetType().fullname
            Throw "Unable to determin the SiteCode for $SiteServer.`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"
        }
    }

    Process {
        Foreach ( $P in $Package ) {
            Write-verbose "Software Updates that are a member of the Software Update Deployment Package : $($P.Name)"

            # ----- using CIM to query the Deployment Package content (SMS_PackageToContent) and Join it with the Config Item content (SMS_CIToContent) thus returnint the CI_ID of the Software Updates in the Software update Deployment Package
            Get-CIMInstance -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -query "SELECT SMS_CITOContent.CI_ID From SMS_CIToContent JOIN SMS_PackageToContent ON SMS_PackageToContent.ContentID=SMS_CIToContent.ContentID where SMS_PackageToContent.PackageID = 'RWV0002D'" | Foreach {
                Write-Output (Get-CMSoftwareUpdate -ID $_.CI_ID -Fast)
            }
       }
    }
}

Get-SCCMSoftwareUpdateMemberOfDeploymentPackage -Package (Get-CMSoftwareUpdateDeploymentPackage -Name Test) -verbose
