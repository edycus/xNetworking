﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

Describe 'Schema Validation MSFT_xIPAddress' {
    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((Get-Item -Path $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xIPAddress'
        $result = Test-xDscResource -Name $path
        $result | Should Be $true
    }

    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((Get-Item -Path $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xIPAddress\MSFT_xIPAddress.schema.mof'
        $result = Test-xDscSchema -Path $path
        $result | Should Be $true
    }
}

if (Get-Module MSFT_xIPAddress -All)
{
    Get-Module MSFT_xIPAddress -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\DSCResources\MSFT_xIPAddress -Force -DisableNameChecking

InModuleScope MSFT_xIPAddress {

    Describe 'Get-TargetResource' {

        #region Mocks
        Mock Get-NetIPAddress {

            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
            }
        }
        #endregion

        Context 'comparing IPAddress' {
            It 'should return true' {

                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = Get-TargetResource @Splat
                $Result.IPAddress | Should Be $Splat.IPAddress
            }
        }

        Context 'Subnet Mask' {
            It 'should fail if passed a negative number' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                    Subnet = -16
                }

                 { Get-TargetResource @Splat } | Should Throw "Value was either too large or too small for a UInt32."
            }
        }
    }


    Describe 'ValidateProperties' {

        #region Mocks
        Mock Get-NetIPAddress -MockWith {

            [PSCustomObject]@{
                IPAddress = '192.168.0.1'
                InterfaceAlias = 'Ethernet'
                PrefixLength = [byte]16
            }
        }

        Mock New-NetIPAddress -MockWith {}

        Mock Get-NetConnectionProfile {
            [PSCustomObject]@{
                Name = 'MSFT'
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                NetworkCategory = 'Public'
                IPV4Connectivity = 'Internet'
                IPV6Connectivity = 'NoTraffic'
            }
        }

        Mock Get-NetIPConfiguration {
            [PSCustomObject]@{
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                IPv4DefaultGateway = [PSCustomObject]@{
                    NextHop = '192.168.0.254'
                }
            }
        }

        Mock Get-NetIPInterface {
            [PSCustomObject]@{
                InterfaceAlias = 'Ethernet'
                InterfaceIndex = 1
                AddressFamily = 'IPv4'
                Dhcp = 'Disabled'
            }
        }

        Mock Set-NetConnectionProfile {}

        Mock Remove-NetIPAddress {}
        #endregion

        Context 'invoking without -Apply switch' {

            It 'should be $false' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $false
            }

            It 'should be $true' {
                $Splat = @{
                    IPAddress = '192.168.0.1'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat
                $Result | Should Be $true
            }
        }

        Context 'invoking with -Apply switch' {

            It 'should be $null' {
                $Splat = @{
                    IPAddress = '10.0.0.2'
                    InterfaceAlias = 'Ethernet'
                }
                $Result = ValidateProperties @Splat -Apply
                $Result | Should BeNullOrEmpty
            }
        }
    }
}
