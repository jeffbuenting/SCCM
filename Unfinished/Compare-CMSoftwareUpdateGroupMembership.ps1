import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:

$Patches = Get-CMSoftwareUpdate -UpdateGroupName 'Patches'
$2015Patches = Get-CMSoftwareUpdate -UpdateGroupName '2015 - Patches'

compare-object $Patches $2015Patches |
