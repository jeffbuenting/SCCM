$NoSession = @()
$ZipInstalled = @()

#$Servers = Get-ADComputer -LDAPFilter "(&(objectcategory=computer)(OperatingSystem=*server*))" -properties OperatingSystem #| where Name -Like QA3*

$Servers = Get-ADComputer -filter *  -properties OperatingSystem 

#$Servers = Get-ADComputer 'WGPQA1-IIS'

$I = 0
foreach ( $S in $Servers ) {
    $I ++
    Write-output "Processing $I = $($S.name)"

    Try {
        $Session = New-PSSession -ComputerName $S.Name -ErrorAction Stop
    }
    Catch {
        $NoSession += $S
        Write-Host $S -ForegroundColor Red
        Continue
    }

    # ----- See if 7zip is installed
    $Zip = invoke-command -Session $Session -ScriptBlock {
        # ----- Payload
                
        $App = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | ?{$_.DisplayName -like "7-Zip*"} 

        Write-Output ( $App | Select-Object *,@{N='ComputerName';E={$env:COMPUTERNAME}})


        # ----- End Payload
    }

    $ZipInstalled += $Zip

    if ( $ZIP.VersionMajor -lt 18 ) {
 
        Write-Output "7Zip Installed"
 
        # ----- Copy 7zip locally to avoid the double hop issue
        if ( -Not ( Test-path -Path "\\$($S.Name)\c$\Temp" ) ) { New-Item -Path "\\$($S.Name)\c$\Temp" -ItemType Directory }
 
        copy-item F:\temp\7z1805-x64.msi -Destination "\\$($S.Name)\c$\Temp" -Force
 
 
        invoke-command -Session $Session -ArgumentList $Zip -ScriptBlock {
            Param ( $ZIPApp )
            # ----- Payload
          
            if ( $ZipApp.UninstallString -eq 'C:\Program Files\7-Zip\Uninstall.exe' ) {
                Write-Output "Uninstalling with Uninstall.exe"
                Start-Process -FilePath $ZIPApp.UninstallString -ArgumentList '/S' -Wait -Verb RunAs
            }
            Else {
               Write-Output "Uninstalling with MSIExec"
               $Guid = $ZipApp.PSChildName          
 
               start-process C:\windows\System32\msiexec.exe -ArgumentList "/X $Guid /qn /norestart" -Wait -Verb RunAs
 
            }
         
            Write-Output "Installing 7Zip"
            start-process C:\windows\System32\msiexec.exe -ArgumentList '/i c:\temp\7z1805-x64.msi /q /norestart' -wait -verb RunAs
            
            # ----- End Payload
        }
    }

    

    Disconnect-PSSession -Session $Session | out-Null 

}


Write-Output "`n`nCould Not Patch"

$NoSession.name | sort-object


"-----------"

$Zip | FT DisplayName,Uninstallstring