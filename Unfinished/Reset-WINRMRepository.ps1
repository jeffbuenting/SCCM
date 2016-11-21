# -------------------------------------------------------------------------------------
# Resets WINRM Repository
#--------------------------------------------------------------------------------------

Function Reset-WINRMRepository {

<#
    .Description
        Resets the WMI Repository on a computer (remote or local).

    .Parameter ComputerName
        List of computers to run reset against.
  
    .Example
        Resets the WMI Repository on a single server.

        Reset-WINRMRepository -ComputerName 'Server1'

    .Example
        Reset the WMI Repository on an array of Servers

        Reset-WINRMRepository -ComputerName 'Server1','Server2'

    .Example
        Same as previous example only using the pipeline

        'Server1','Server2' | Reset-WINRMRepository

    .Link
        WinMgmt won't stop if dependent services are running.  This article discusses how to get around that error.
            http://visualplanet.org/blog/?p=274
       
        Original SCCM error that resulted in this Function
            http://trevorsullivan.net/2009/11/06/wmi-repository-corruption-sccm-client-fix/
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String[]]$ComputerName
    )

    Process {
        Foreach ( $C in $ComputerName ) {
            Write-Verbose "Resetting WINRM Repository on computer $ComputerName"

            Invoke-Command -ComputerName $C -ScriptBlock { 
                # ----- Get running dependent services so we can restart them
                $DependentServices = (Get-Service -Name WinMgmt).DependentServices | where Status -eq 'Running'
                                 
                # ----- Stop WinMgmt Service and reset Repository
                Stop-Service winmgmt -Force 
                winmgmt /resetrepository

                # ----- Restart Dependent Services
                $DependentServices | Start-Service
            } 
        }
    }
}

'rwva-ts1' | Reset-WINRMRepository -Verbose