import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Import-Module C:\Scripts\SCCM\SCCM_Module.psm1 -force

set-location RWV:

$InstalledPatches = get-hotfix -ComputerName 'cl-hyperv2' | where InstalledOn -eq '9/19/2015'
$SUGPatches = Get-CMSoftwareUpdate -UpdateGroupName '2015 - Patches'

$SUGPatches


foreach ( $P in $InstalledPatches ) { 
    if ( $P.HotfixID -notin $SUGPatches ) { 
        $P.HotFixID 
    }
}

