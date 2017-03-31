$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

## ----- Import the ConfigurationManager module and set to the site.
#import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

#set-location RWV:

Describe "Get-SCCMSoftwareUpdateMemberOfDeploymentPackage" {
    
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
    Context "Help" {
        
        $H = Help Get-SCCMSoftwareUpdateMemberOfDeploymentPackage -Full

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
      

    Context "Execution" {
       
        Mock -CommandName Get-CMSoftwareUpdate {
            return @{
                ArticleID = 4010250
                CI_ID = 16964010
            }    
        }

        $DP = Get-CMSoftwareUpdate -ArticleID 4010250 #| Get-SCCSoftwareUpdateMemberofDeploymentPackage

        Write-Verbose "$($DP | out-string)"
        
        It "Returns a list of Software Update Deployment Packages" {
         

        }
    }

}
