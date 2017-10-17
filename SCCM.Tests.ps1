$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path

$ModuleName = $ModulePath | Split-Path -Leaf

# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop -Scope Global -Verbose

#-------------------------------------------------------------------------------------

Write-Output "`n`n"

Describe "SCCM : Get-SCCMSoftwareUpdateDeploymentPackage" {
    Context "Help" {
        $H = Help Get-SCCMSoftwareUpdateDeploymentPackage -Full
        
        # ----- Help Tests
        It "has Synopsis Help Section" {
            $H.Synopsis | Should Not BeNullorEmpty
        }

        It "has Description Help Section" {
            $H.Description | Should Not BeNullorEmpty
        }

        It "has Parameters Help Section" {
            $H.Parameters | Should Not BeNullorEmpty
        }

        # Examples - Remarks (small description that comes with the example)
        foreach ($Example in $H.examples.example)
        {
            it "Example - Remarks on $($Example.Title)"{
                $Example.remarks | Should not BeNullOrEmpty
            }
        }

        It "has Notes Help Section" {
            $H.alertSet | Should Not BeNullorEmpty
        }
    } 
    
    Mock -CommandName Get-CimInstance -ParameterFilter { $classname -eq 'SMS_ProviderLocation' } -MockWith {
        $Obj = New-Object -TypeName PSObject -Property (@{
            SiteCode = "ABC"
        })
        
        Write-Output $Obj
    }

    Context Execution {
        
        It "Throws an error if the site code cannot be determined" {
            Mock -CommandName Get-CimInstance -MockWith {
                Throw "oops"
            }

            { Get-SCCMSoftwareUpdateDeploymentPackage -SiteServer 'wrong' } | Should Throw
        }

        It "Filtered : Throws an error if it fails retrieving Named Deployment packages" {
            Mock -CommandName Get-CimInstance { $classname -eq 'SMS_SoftwareUpdatesPackage' } -MockWith {
                Throw "oops"
            }

            { Get-SCCMSoftwareUpdateDeploymentPackage -SiteServer 'ServerA' -Name 'DP' } | Should Throw
        } 

        It "All : Throws an error if it fails retrieving Deployment packages" {
            Mock -CommandName Get-CimInstance { $classname -eq 'SMS_SoftwareUpdatesPackage' } -MockWith {
                Throw "oops"
            }

            { Get-SCCMSoftwareUpdateDeploymentPackage -SiteServer 'ServerA' } | Should Throw
        } 


    }

    Context Output {

        It "Filtered : Returns a custom Deployment Package object if a name is included" {
            Mock -CommandName Get-CimInstance -ParameterFilter { $className -eq 'SMS_SoftwareUpdatesPackage'  } -MockWith {
                $Obj = New-Object -TypeName PSObject -Property (@{
                    Name = 'DP'
                })
        
                Write-Output $Obj
            }

            Get-SCCMSoftwareUpdateDeploymentPackage -SiteServer 'ServerA' -Name 'DP' | Should BeOfType PSObject

        } 

        It "All : Returns a custom Deployment Package object when requesting all." {
            Mock -CommandName Get-CimInstance -ParameterFilter { $className -eq 'SMS_SoftwareUpdatesPackage'  } -MockWith {
                $Obj = New-Object -TypeName PSObject -Property (@{
                    Name = 'DP'
                })
        
                Write-Output $Obj
            }

            Get-SCCMSoftwareUpdateDeploymentPackage -SiteServer 'ServerA' | Should BeOfType PSObject
        } 
    }
}

