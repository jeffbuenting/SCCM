Function Get-CMComponentStatusDescription {

<#
    .Link
        SMS_StatMsgModuleNames Server WMI Class : https://msdn.microsoft.com/en-us/library/hh949622.aspx

    .Link
        SMS_StatusMessage Server WMI Class : https://msdn.microsoft.com/en-us/library/hh948550.aspx
        Get-CMComponentStatusMessage
#>

    [CmdletBinding()]
    Param (
        
       

        [Parameter ( Mandatory = $True, ValuefromPipeline = $True )]
        [PSObject]$StatusMessage,

        [Parameter (Mandatory = $True)]
        [String]$SCCMServer
    )

    Begin {
        # ----- https://msdn.microsoft.com/en-us/library/hh949622.aspx

       
        Write-Verbose "Retrieving DLL Real names from $SCCMServer"
        $DLL = get-ciminstance -computername $SCCMServer -ClassName sms_StatMsgModuleNames -Namespace root\sms\site_RWV

    }

    Process {
        # -----If the status message is in Srvmsgs.dll, Provmsgs.dll, or Climmsgs.dll, you can use FormatModuleMessage Method to resolve the message
        # https://msdn.microsoft.com/en-us/library/jj218288.aspx
        # https://msdn.microsoft.com/en-us/library/hh949207.aspx

        $Message = New-Object -COMObject SMSFormatMessageCTL

        $StatusMessage
    }

}

import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:

get-cmcomponentstatusmessage -ViewingPeriod "08/03/2016 12:00AM" -ComponentName SMS_WSUS_SYNC_MANAGER -Severity all | Get-CMComponentStatusDescription -SCCMServer rwva-sccm -Verbose

#| foreach {
#
#    $_
#    "-----------------"
#     
#     $_.ModuleName
#     $_.MessageID
#     $_.Severity
#}
 
