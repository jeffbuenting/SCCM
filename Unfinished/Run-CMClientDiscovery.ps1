# ----- Run-CMClientDiscovery
import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Import-Module C:\Scripts\SCCM\SCCM_Module.psm1

set-location RWV:

Get-CMDeviceCollection -Name '2 - Deploy to Dev' | Get-CMDeviceCollectionMember | Select-Object -ExpandProperty Name | Start-CMClientAction -Action Discovery -verbose
