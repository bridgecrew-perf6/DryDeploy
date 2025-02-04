﻿Using NameSpace System.Management.Automation
Using NameSpace System.Management.Automation.Runspaces
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
Function Copy-DryADModulesToRemoteTarget {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [PSSession]
        $PSSession,

        [Parameter(Mandatory)]
        [String]
        $RemoteRootPath,

        [Parameter(Mandatory)]
        [Array]
        $Modules,

        [Parameter(HelpMessage = 'Forcefully import the modules, so any previously imported versions are replaced')]
        [Switch]
        $Import
    )

    try {
        # While copying multiple tiny files, the progress bar is flickering and not informative at all, so suppress it
        $OriginalProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
       
        $InvokeDirParams = @{
            ScriptBlock  = $DryAD_SB_RemoveAndReCreateDir
            Session      = $PSSession
            ArgumentList = @($RemoteRootPath)
        }
        $DirResult = Invoke-Command @InvokeDirParams
        
        Switch ($DirResult) {
            $True {
                ol d 'Created remote directory', "$RemoteRootPath"
            }
            { $DirResult -is [ErrorRecord] } {
                ol w 'Unable to create remote directory', "$RemoteRootPath"
                $PSCmdlet.ThrowTerminatingError($DirResult)
            }
            Default {
                Throw "Unable to create remote directory: $($DirResult.ToString())"
            }
        }

        ForEach ($Module in $Modules) {
            [PSModuleInfo]$ModuleObj = Get-Module -Name $Module -ListAvailable -ErrorAction Stop
            if ($null -eq $ModuleObj) {
                throw "Unable to find module '$Module'"
            }
            else {
                $ModuleFolder = Split-Path -Path $ModuleObj.Path
                $CopyItemsParams = @{
                    Path        = $ModuleFolder
                    Destination = $RemoteRootPath 
                    ToSession   = $PSSession 
                    Recurse     = $True
                    Force       = $True
                }
                ol d @("Copying module to '($PSSession.ComputerName)'", "'$ModuleFolder'")
                Copy-Item @CopyItemsParams
            }
        }
        
        # Add RemoteRootPath to $env:PSModulePath on the remote system, so functions are
        # available without explicit import. Prepare $RemoteRootPath and a $RemoteRootPathRegex 
        # that allows us to test if the path is already added or not. 
        
        # Change double backslash to single, remove trailing backslash, and lastly make all 
        # single backslashes double in the regex
        $RemoteRootPath = ($RemoteRootPath.Replace('\\', '\')).TrimEnd('\')         
        $RemoteRootPathRegEx = $RemoteRootPath.Replace('\', '\\')

        $InvokePSModPathParams = @{
            ScriptBlock  = $DryAD_SB_PSModPath
            Session      = $PSSession 
            ArgumentList = @($RemoteRootPath, $RemoteRootPathRegEx)
        }
        $RemotePSModulePaths = Invoke-Command @InvokePSModPathParams

        ol d @('The PSModulePath on remote system', "'$RemotePSModulePaths'")
        Switch ($RemotePSModulePaths) {
            { $RemotePSModulePaths -Match $RemoteRootPathRegEx } {
                ol v @('Successfully added to remote PSModulePath', "'$RemoteRootPath'")
            }
            Default {
                ol w @('Failed to add path to remote PSModulePath', "'$RemoteRootPath'")
                Throw "The RemoteRootPath '$RemoteRootPath' was not added to the PSModulePath in the remote session"
            }
        }

        If ($Import) {
            $ImportModsParams = @{
                Session      = $PSSession 
                ScriptBlock  = $DryAD_SB_ImportMods 
                ArgumentList = @($Modules)
                ErrorAction  = 'Stop' 
            }   
            $ImportResult = Invoke-Command @ImportModsParams
    
            Switch ($ImportResult) {
                $True {
                    ol s "Modules were imported into the session"
                    ol v "The modules '$Modules' were imported into PSSession to $($PSSession.ComputerName)"
                }
                Default {
                    ol f "Modules were not imported into the session"
                    ol w "The modules '$Modules' were not imported into PSSession to $($PSSession.ComputerName)"
                    Throw "The modules '$Modules' were not imported into PSSession to $($PSSession.ComputerName)"
                }
            }
        }
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    Finally {
        $ProgressPreference = $OriginalProgressPreference
    }
}
