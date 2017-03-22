$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Remove-SCCMSoftwareUpdateFromGroup" {
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
    Context "Help" {

        $H = Help Remove-SCCMSoftwareUpdateFromGroup -Full

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
        
        Mock Get-CMSoftwareUpdateGroup {
            Return ( 
                @{
                    'LocalizedDisplayName' = 'Test';
                    'Updates' = 2310138,3198389,3186207
                },

                @{
                    'LocalizedDisplayName' = 'Test2';
                    'Updates' = 2310138,3198389,378295,123456
                }
            )
        } -ModuleName ConfigurationManager

  #      Mock Get-CMSoftwareUpdateGroup {
  #          Return @{
  #              'LocalizedDisplayName' = 'Test';
  #              'Updates' = 2310138,3198389,31862077
  #          }
  #      } -ParameterFilter { $Name } -ModuleName ConfigurationManager

        Mock Get-CMSoftwareUpdate {
            Return @{
                'CI_ID' = 2310138
                'IsSuperseded' = $False
                'IsExpired' = $True
            }
        } -ModuleName ConfigurationManager

        It "Removes updates from the software update Group" {
           Get-CMSoftwareUpdate -UpdateGroupName  | where { $_.issuperseded -or $_.IsExpired } | Remove-sccmSoftwareUpdateFromGroup -verbose

        }
    }
}