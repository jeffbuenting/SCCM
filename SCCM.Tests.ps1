# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$ModulePath = $PSScriptRoot

$Global:ModuleName = $ModulePath | Split-Path -Leaf

# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop  -verbose


InModuleScope $ModuleName {

    #-------------------------------------------------------------------------------------
    # ----- Check if all fucntions in the module have a unit tests

    Describe "$ModuleName : Module Tests" {

        $Module = Get-module -Name $ModuleName -Verbose

        $testFile = Get-ChildItem $module.ModuleBase -Filter '*.Tests.ps1' -File -verbose
    
        $testNames = Select-String -Path $testFile.FullName -Pattern 'describe\s[^\$](.+)?\s+{' | ForEach-Object {
            [System.Management.Automation.PSParser]::Tokenize($_.Matches.Groups[1].Value, [ref]$null).Content
        }

        $moduleCommandNames = (Get-Command -Module $ModuleName | where CommandType -ne Alias)

        it 'should have a test for each function' {
            Compare-Object $moduleCommandNames $testNames | where { $_.SideIndicator -eq '<=' } | select inputobject | should beNullOrEmpty
        }
    }

    



    #-------------------------------------------------------------------------------------

    Write-Output "`n`n"

    Describe "$ModuleName : Get-CMDeviceCollectionMember" {

        # ----- Get Function Help
        # ----- Pester to test Comment based help
        # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

        Context "Help" {
            
            $H = Help Get-CMDeviceCollectionMember -Full | Out-String

            # ----- Appveyor is converting this help to a string.  I don't know why.  SO I have to convert it to an object otherwise the tests will completely fail even if they are true.
            if ( $H.GetType().Name -eq 'String' ) {
    
                $HelpObject = New-Object -TypeName PSObject

                # ----- Get Name
                $H -match 'NAME[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Name -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Synopsis
                $H -match 'SYNOPSIS[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Synopsis -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Description
                $H -match 'DESCRIPTION[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Description -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Parameters
                $H -match 'PARAMETERS[\r\n]+([\-\s\r\n\S]+?(?=[\s\r\n]+<CommonParameters>))'
                $Parameter = @()
    
                $Matches[1] | Foreach {
                    $P = New-Object -TypeName PSObject -Property (@{
                        'Parameter' = New-Object -TypeName PSObject -Property (@{
                            'Description' = $_
                        })
                    })
        
                    $Parameter += $P
                }

                $HelpObject | Add-Member -MemberType NoteProperty -Name Parameters -Value $Parameter


                # ----- Get Notes
                $H -match 'NOTES[\s\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Alertset -Value $Matches[1].TrimStart( ' ' )

                $Matches

                # ----- Get Examples
                $H -match '-* EXAMPLE 1 -*[\s\r\n]+(.*)'
                $E = New-Object -TypeName PSObject -Property (@{
                    'Example' = New-Object -TypeName PSObject -Property (@{
                        'Remarks' = $Matches[1]
                    })
                })

                $HelpObject | Add-Member -MemberType NoteProperty -Name Examples -Value $E


                $H = $HelpObject
            }

            # ----- Help Tests
            It "has Synopsis Help Section" {
                 $H.Synopsis  | Should Not BeNullorEmpty
            }

            It "has Synopsis Help Section that it not start with the command name" {
                $H.Synopsis | Should Not Match $H.Name
            }

            It "has Description Help Section" {
                 $H.Description | Should Not BeNullorEmpty
            }

            It "has Parameters Help Section" {
                 $H.Parameters.parameter.description  | Should Not BeNullorEmpty
            }

            # Examples
            it "Example - Count should be greater than 0"{
                 $H.examples.example  | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterthan 0
            }
            
            # Examples - Remarks (small description that comes with the example)
            foreach ($Example in $H.examples.example)
            {
                it "Example - Remarks on $($Example.Title)"{
                     $Example.remarks  | Should not BeNullOrEmpty
                }
            }

            It "has Notes Help Section" {
                 $H.alertSet  | Should Not BeNullorEmpty
            }

        } 

        $Collection = New-Object -TypeName PSObject -Property (@{
            'CollectionID' = 'AAA0003'
        })

        Function Get-CMSite {}

        Mock -CommandName Get-CMSite -MockWith {
            $Obj = New-Object -TypeName PSObject -Property (@{
                'ServerName' = 'SCCMServer'
                'SideCode' = 'SCM'
            })

            Return $Obj
        }

        Mock -CommandName Get-CimInstance -MockWith {
            $Obj = New-Object -TypeName PSObject -Property @{
                'Name'='membername'
            }

            Return $Obj
        }

        Context Execution {
            
            It 'Should not throw an error if there are no problems' {
                { $Collection | Get-CMDeviceCollectionMember } | Should Not Throw
            }

        }

        Context Output {
            
            It 'SHould Return a collection membership object' {
                $Collection | Get-CMDeviceCollectionMember | Should BeofType PSObject
            }

        }
    }

    #-------------------------------------------------------------------------------------

    Write-Output "`n`n"

    Describe "$ModuleName : Start-CMClientAction" {

        # ----- Get Function Help
        # ----- Pester to test Comment based help
        # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

        Context "Help" {
            
            $H = Help Start-CMClientAction -Full

            # ----- Appveyor is converting this help to a string.  I don't know why.  SO I have to convert it to an object otherwise the tests will completely fail even if they are true.
            if ( $H.GetType().Name -eq 'String' ) {
    
                $HelpObject = New-Object -TypeName PSObject

                # ----- Get Name
                $H -match 'NAME[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Name -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Synopsis
                $H -match 'SYNOPSIS[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Synopsis -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Description
                $H -match 'DESCRIPTION[\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Description -Value $Matches[1].TrimStart( ' ' )

                # ----- Get Parameters
                $H -match 'PARAMETERS[\r\n]+([\-\s\r\n\S]+?(?=[\s\r\n]+<CommonParameters>))'
                $Parameter = @()
    
                $Matches[1] | Foreach {
                    $P = New-Object -TypeName PSObject -Property (@{
                        'Parameter' = New-Object -TypeName PSObject -Property (@{
                            'Description' = $_
                        })
                    })
        
                    $Parameter += $P
                }

                $HelpObject | Add-Member -MemberType NoteProperty -Name Parameters -Value $Parameter


                # ----- Get Notes
                $H -match 'NOTES[\s\r\n]+(.*)'
                $HelpObject | Add-Member -MemberType NoteProperty -Name Alertset -Value $Matches[1].TrimStart( ' ' )

                $Matches

                # ----- Get Examples
                $H -match '-* EXAMPLE 1 -*[\s\r\n]+(.*)'
                $E = New-Object -TypeName PSObject -Property (@{
                    'Example' = New-Object -TypeName PSObject -Property (@{
                        'Remarks' = $Matches[1]
                    })
                })

                $HelpObject | Add-Member -MemberType NoteProperty -Name Examples -Value $E


                $H = $HelpObject
            }

            # ----- Help Tests
            It "has Synopsis Help Section" {
                 $H.Synopsis  | Should Not BeNullorEmpty
            }

            It "has Synopsis Help Section that it not start with the command name" {
                $H.Synopsis | Should Not Match $H.Name
            }

            It "has Description Help Section" {
                 $H.Description | Should Not BeNullorEmpty
            }

            It "has Parameters Help Section" {
                 $H.Parameters.parameter.description  | Should Not BeNullorEmpty
            }

            # Examples
            it "Example - Count should be greater than 0"{
                 $H.examples.example  | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterthan 0
            }
            
            # Examples - Remarks (small description that comes with the example)
            foreach ($Example in $H.examples.example)
            {
                it "Example - Remarks on $($Example.Title)"{
                     $Example.remarks  | Should not BeNullOrEmpty
                }
            }

            It "has Notes Help Section" {
                 $H.alertSet  | Should Not BeNullorEmpty
            }

        } 

        Mock Get-WMIObject -MockWith {
            $Obj = New-Object -TypeName PSObject -Property (@{
                'Name' = 'SMS_Client'
            })

            $Obj | Add-Member -MemberType ScriptMethod -Name TriggerSchedule -Value {
                Param ( $Action )
            } -Force 

            Return $Obj
        } -Verifiable

        Context Execution {
            
            It "Should work with single computername as Input" {
                { Start-CMClientAction -ComputerName 'Server' -Action HardwareInventory } | Should Not Throw

                Assert-VerifiableMock 
            }

            It "Should work with array of computernames passed in" {
                { Start-CMClientAction -ComputerName 'Server','ServerA' -Action HardwareInventory } | Should Not Throw

                Assert-VerifiableMock 
            }

            It "Should work with Pipeline Input" {
                { 'Server','ServerA' | Start-CMClientAction  -Action HardwareInventory } | Should Not Throw

                Assert-VerifiableMock 
            }
           
        }

    }



















}

