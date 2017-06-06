<#
    .Synopsis
        Clears client cache for all devices in the specified collection

    .Description
        Sometimes deployments hang and won't start until they have redownloaded their files.  Or other issues that require the clients cache to be cleared.  This script 
        gets all devices in a collection and clear the cache.

    .Note
        Requires the SCCM Custom module developed by Jeff Buenting

    .Note
        Author : Jeff Buenting
        Date : 2017 JUN 05
#>

$Site = 
$Collection = '7 - Production (Sunday Morning'

import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location $($Site):

Get-CMDevicecollection -Name $Collection | Get-CMDeviceCollectionMember | Select-object -ExpandProperty name  | Clear-SCCMClientCache -verbose
