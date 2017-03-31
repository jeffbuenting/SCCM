$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Remove-SCCMSoftwareUpdateFromDeploymentPackage" {
   
   # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
    Context "Help" {

        $H = Help Remove-SCCMSoftwareUpdateFromDeploymentPackage -Full

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

        # Examples
        it "Example - Count should be greater than 0"{
            $H.examples.example.code.count | Should BeGreaterthan 0
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

    # ----- Checks various things inside of the function to keep things standard.
    Context "Function must include" {
        $Funct = Get-Content "$here\$sut" -Raw

        
        # ----- allows common variables and output steams
        It "has [CmdletBinding()] followed by Param (" {
            $Funct | Should Match "\[CmdletBinding\(\)\]\r\n.*Param \("
        }

    }

    Context "Execution" {
        
       It "Removes updates from the software update from DeploymentGroup" {
         

        }
    }
}
