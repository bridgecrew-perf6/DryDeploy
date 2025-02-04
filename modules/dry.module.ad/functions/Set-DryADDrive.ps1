﻿Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#>
Function Set-DryADDrive {
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    Param ( 
        [Parameter(Mandatory, ParameterSetName = 'Remote',
            HelpMessage = "PSSession to run the script blocks in")]
        [PSSession] 
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [String] 
        $DomainController
    )

    try {
        If ($PSCmdlet.ParameterSetName -eq 'Remote') {
            ol i @("Making sure AD Drive on DC $($PSSession.ComputerName) targets", 'localhost')
            $Server = 'localhost'
            ol d @('Session Type', 'Remote')
            ol d @('Remoting to Domain Controller', $PSSession.ComputerName)
        }
        Else {
            ol i @('Making sure AD Drive on local system targets DC', "$DomainController")
            $Server = $DomainController
            ol d @('Session Type', 'Local')
            ol d @('Using Domain Controller', $Server)
        }
        
        $ArgumentList = @($Server)
        $InvokeParams = @{
            ScriptBlock  = $DryAD_SB_ADDrive_Set
            ArgumentList = $ArgumentList
        }
        If ($PSCmdlet.ParameterSetName -eq 'Remote') {
            $InvokeParams += @{
                Session = $PSSession
            }
        }
        $Return = $Null; $Return = Invoke-Command @InvokeParams

        # Send every string in $Return[0] to Degug via Out-DryLog
        ForEach ($ReturnString in $Return[0]) {
            ol d "$ReturnString"
        }
        
        # Test the ReturnValue in $Return[2]
        If ($Return[1] -eq $True) {
            ol s 'AD Drive Configured'
            ol v "Successfully set AD Drive to target Domain Controller"
        } 
        Else {
            ol f 'AD Drive Not Configured'
            ol w "Failed to set AD Drive to target Domain Controller"
            If ($Null -ne $Return[2]) {
                Throw ($Return[2]).ToString()
            } 
            Else {
                Throw "ReturnValue false, but no ErrorRecord returned - check debug"
            }
        }  
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
