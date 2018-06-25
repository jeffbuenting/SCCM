import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:

# ----- Get Devices that CRM knows about that do not have the client installed
Get-CMDevice | where { ( $_.IsClient -eq $False ) -and ( $_.Name -ne 'RWVA' ) } | Foreach {
    
    Write-Output "Installing SCCM client on $($_.Name)"
    
    # ----- Skip device is cannot ping
    if ( Test-Connection -ComputerName $_.Name -Quiet ) { 
    
        # ----- Because I am lazy and have not configured the Install account to be a member of the local admin on each machine.  I add it here.
        # ----- Need admin rights on machine to install SCCM Client.  We use the SCCMNaa account for this.
        if ( (Get-LocalGroup -computerName $Server -Group Administrators | Get-LocalGroupMember) -notcontains 'stratuscloud1\sccmnaa' ) {
    
            invoke-command -ComputerName $Server  -ScriptBlock {
                ([ADSI]"WinNT://$using:Server/Administrators,group").Add("WinNT://stratuscloud1/sccmnaa")
            }
        }
    }
}

