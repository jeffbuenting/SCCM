$NoSession = @()
$ZipInstalled = @()

$Servers = Get-ADComputer -LDAPFilter "(&(objectcategory=computer)(OperatingSystem=*server*))" -properties OperatingSystem #| where Name -Like QA3*

#$Servers = Get-ADComputer -filter *  -properties OperatingSystem 

#$Servers = Get-ADComputer 'JB-CRM02'

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

    
    invoke-command -Session $Session -ScriptBlock {
        # ----- Payload
        
# ----- Creates registry entries to enable Spectre CVE-2017-5715_5753_5754
# https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution
# ----- Requires Monthly Cumulative rollups

if ( -Not ( Get-Item -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization' -ErrorAction SilentlyContinue ) ) {
    New-Item -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'
}
    
# ----- Create entry
if ( -Not ( Get-Item -Path 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\FeatureSettingsOverride' -ErrorAction SilentlyContinue ) ) {
    Set-ItemProperty -Path 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name FeatureSettingsOverride -type DWORD -Value 0
}

if ( -Not ( Get-Item -Path 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue ) ) {
    Set-ItemProperty -Path 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name FeatureSettingsOverrideMask -type DWORD -Value 3
}

if ( -Not ( Get-Item -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\MinVmVersionForCpuBasedMitigations' -ErrorAction SilentlyContinue ) ) {
    Write-output 'One'
    Set-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization' -Name MinVmVersionForCpuBasedMitigations -Value '1.0' 
}


        # ----- End Payload
    }

    

    

    Disconnect-PSSession -Session $Session | out-Null 

}


Write-Output "`n`nCould Not Patch"

$NoSession.name | sort-object


"-----------"

$Zip | FT DisplayName,Uninstallstring