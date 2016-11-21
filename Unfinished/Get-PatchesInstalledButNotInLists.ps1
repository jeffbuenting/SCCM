$Patch = 'KB3092627'

$ComputerName = 'cl-hyperv1','cl-hyperv2','cl-hyperv3','cl-hyperv4','cl-hyperv5','cl-hyperv6'

Write-Output "Getting SUG Patches"
$SUGPatches = Get-CMSoftwareUpdate -UpdateGroupName '2015 - Patches'

Write-output "Getting Baseline Patches"
$BaselinePatches = (Get-SCBaseline -VMMServer 'rwva-scvmm' -Name '2015 - Patches').Updates

Write-Output "Getting Installed Patches"
$InstalledPatches = get-hotfix -ComputerName $ComputerName | where InstalledOn -eq '9/19/2015'

$NotInBaseline = @()
$NotinSUG = @()

foreach ( $P in $InstalledPatches ) {
    if ( ($P.HotFixID -replace 'KB','')  -notin $BaselinePatches.KBArticle ) {
        if ( ($P.HotFixID -replace 'KB','') -notin $NotInBaseline ) { $NotinBaseline += $P }
        if ( ($P.HotFixID -replace 'KB','') -notin $SUGPatches.ArticleID ) {
            if ( ($P.HotFixID -replace 'KB','') -Notin $NotInSUG ) { $NotinSUG += $P }
        }
    }
}

"Not in Baseline"
$NotinBaseline

"Not in SUG"
$NotinSUG