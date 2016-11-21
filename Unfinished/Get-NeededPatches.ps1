import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Import-Module C:\Scripts\SCCM\SCCM_Module.psm1 -force

set-location RWV:

$SUGPatches = Get-CMSoftwareUpdate -UpdateGroupName '2015 - Patches'

$SUGPatches



$ComputerName = 'rwva-sccm'

$NeededPatches = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    Write-Output (get-wuinstall -MicrosoftUpdate -listonly)
}

$NeededPatches.count



foreach ( $P in $NeededPatches ) { 
    $P.KB.substring(2)
    if ( $P.KB.substring(2) -notin $SUGPatches.Articleid ) { 
        Write-Warning $P.KB 
    }
}