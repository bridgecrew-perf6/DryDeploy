﻿Using Namespace System.Management.Automation.Runspaces
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
Function Set-DryADGPLink {
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    Param (
        [Parameter(Mandatory, HelpMessage = "Object containing description av an OU and set of ordered GPLinks")]
        [PSObject]
        $GPOLinkObject,

        [Parameter(Mandatory)]
        [String]
        $DomainFQDN,

        [Parameter(Mandatory)]
        [String]
        $DomainDN,

        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [PSSession]
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [String]
        $DomainController
    )

    If ($PSCmdLet.ParameterSetName -eq 'Remote') {
        $Server = 'localhost'
        ol v @('Session Type', 'Remote')
        ol v @('Remoting to Domain Controller', "$($PSSession.ComputerName)")
    }
    Else {
        $Server = $DomainController
        ol v @('Session Type', 'Local')
        ol v @('Using Domain Controller', "$Server")
    }
  
    # Add the domainDN to $OU if not already done
    If ($GPOLinkObject.Path -notmatch "$DomainDN$") {
        If (($GPOLinkObject.Path).Trim() -eq '') {
            # The domain root
            $GPOLinkObject.Path = $DomainDN
        }
        Else {
            $GPOLinkObject.Path = $GPOLinkObject.Path + ',' + $DomainDN
        }
    }
    ol v @('Linking GPOs to', "$($GPOLinkObject.Path)") 

    try {
        # Order the GPOLinks by its 'order'-property
        $GPOLinkObject.gplinks = $GPOLinkObject.gplinks | Sort-Object -Property 'order'
       
        $GetCurrentLinksArgumentList = @(
            $GPOLinkObject.Path,
            $Server
        )

        $GetInvokeParams = @{
            ScriptBlock  = $DryAD_SB_GPLink_Get
            ArgumentList = $GetCurrentLinksArgumentList
        }
        If ($PSCmdLet.ParameterSetName -eq 'Remote') {
            $GetInvokeParams += @{
                Session = $PSSession
            }
        }
        $CurrentLinks = Invoke-Command @GetInvokeParams
        
        # If $CurrentLinks[1] is an empty string, the remote command succeeded
        If ($CurrentLinks[1] -eq '') {
            If ($CurrentLinks[0].count -eq 0) {
                ol v 'No GPOs are currently linked to', "$($GPOLinkObject.Path)"
            }
            Else {
                [Array]$CurrentLinkNames = $CurrentLinks[0]
                $CurrentLinkNames.Foreach( { ol v 'Current Link', "$_" })
            }
        } 
        Else {
            Throw $CurrentLinks[1]
        }

        <#
            Create the current link table, which is a list of objects with properties
            .Name     = "My Awesome GPO - v1.0.3"
            .BaseName = "My Awesome GPO - "
            .Version  = "v1.0.3"
        #>
        [System.Collections.Generic.List[PSObject]]$CurrentLinkTable = @()
        ForEach ($LinkName in $CurrentLinkNames) {
            Switch -regex ($LinkName) {
                # ex V1.45.9
                "v[0-9]{1,5}\.[0-9]{1,5}\.[0-9]{1,5}$" {
                    $LinkBaseName = ($LinkName).TrimEnd($($matches[0]))
                    #$LinkVersion = $matches[0]
                    $v = $matches[0]
                    $LinkVersion = [system.version]"$($v.Trim('V').Trim('v'))"
                }
                # ex v3r9 (like DoD Baselines)
                "v[0-9]{1,5}r[0-9]{1,5}$" {
                    $LinkBaseName = ($LinkName).TrimEnd($($matches[0]))
                    #$LinkVersion = $matches[0]
                    $v = $matches[0]
                    $LinkVersion = [system.version]"$($(($v -isplit 'v') -isplit 'r')[1]).$($(($v -isplit 'v') -isplit 'r')[2])"
                }
                # no versioning
                Default {
                    $LinkBaseName = $LinkName
                    $LinkVersion = ''
                }
            }
            $CurrentLinkTable += New-Object -TypeName PSObject -Property @{
                Name     = $LinkName
                BaseName = $LinkBaseName
                Version  = $LinkVersion
            }
            Remove-Variable -Name LinkBaseName, LinkVersion -ErrorAction Stop
        }

        # Loop through all links
        ForEach ($GPLink in $GPOLinkObject.GPLinks) {
            try {
                # Get the basename of the GPO (versioning trimmed off). 
                Switch -regex ($GPLink.Name) {
                    # ex V1.45.9
                    "v[0-9]{1,5}\.[0-9]{1,5}\.[0-9]{1,5}$" {
                        $BaseName = ($GPLink.Name).TrimEnd($($matches[0]))
                        #$Version = $matches[0]
                        $v = $matches[0]
                        $Version = [system.version]"$($v.Trim('V').Trim('v'))"
                    }
                    # ex v3r9 (like DoD Baselines)
                    "v[0-9]{1,5}r[0-9]{1,5}$" {
                        $BaseName = ($GPLink.Name).TrimEnd($($matches[0]))
                        #$Version = $matches[0]
                        $v = $matches[0]
                        $Version = [system.version]"$($(($v -isplit 'v') -isplit 'r')[1]).$($(($v -isplit 'v') -isplit 'r')[2])"
                    }
                    # no versioning
                    Default {
                        $BaseName = $GPLink.Name
                        $Version = ''
                    }
                }
                $GPLink | Add-Member -MemberType NoteProperty -Name 'BaseName' -Value $BaseName
                $GPLink | Add-Member -MemberType NoteProperty -Name 'Version' -Value $Version 

                # Links get enabled by default. Override if explicitly set to disabled in GPLink object
                # Accept boolean $False as well as 'No'. The GP-cmdlets uses 'Yes' and 'No'
                $LinkEnabled = 'Yes'
                If (
                    ($GpLink.LinkEnabled -eq 'No') -or 
                    ($GpLink.LinkEnabled -eq $False)
                ) {
                    $LinkEnabled = 'No'
                }
                
                # Enforce if explicitly set in the GPLink object
                $Enforced = 'No'
                If (
                    ($GpLink.Enforced -eq 'Yes') -or 
                    ($GpLink.Enforced -eq $True)
                ) {
                    $Enforced = 'Yes'
                }

                # Test if there is a match for this GPO name in $CurrentLinkTable
                $CurrentlyLinkedMatch = $CurrentLinkTable | Where-Object { 
                    $_.Name -eq $GPLink.Name 
                }
                
                If ($CurrentlyLinkedMatch) {
                    ol v "The GPO '$($GPLink.Name)' is already linked to '$($GPOLinkObject.Path)'"

                    # However, run Set-GPLink to enforce Order, Enforce and LinkEnabled
                    $SetLinkArgumentList = @(
                        $GPOLinkObject.Path,
                        $GPLink.Name,
                        $GPLink.Order,
                        $LinkEnabled,
                        $Enforced,
                        $Server
                    )
                    $InvokeSetLinkParams = @{
                        ScriptBlock  = $DryAD_SB_GPLink_Set
                        ArgumentList = $SetLinkArgumentList
                        ErrorAction  = 'Stop'
                    }

                    If ($PSCmdLet.ParameterSetName -eq 'Remote') {
                        $InvokeSetLinkParams += @{
                            Session = $PSSession
                        }
                    }
                    ol i @('GPO', "$($GPLink.Name)")
                    $SetLinkRet = Invoke-Command @InvokeSetLinkParams
                    
                    If ($SetLinkRet[0] -eq $True) {
                        ol v "Successfully updated GPlink properties for '$($GPLink.Name)' on $($GPOLinkObject.Path)"
                        ol s "Link updated"
                    }
                    Else {
                        ol f "Link updated"
                        Throw $SetLinkRet[1]
                    }

                    # Jump to next link
                    Continue
                }

                # If there are lower-versioned GPOs linked, those links should be removed. If 
                # there are higher-versioned GPOs linked, throw an error
                $CurrentlyLinkedBaseMatches = @($CurrentLinkTable | Where-Object { $_.BaseName -eq $GPLink.BaseName })
                If ($CurrentlyLinkedBaseMatches) {
                    $Unlink = @()
                    ForEach ($BaseNameMatch in $CurrentlyLinkedBaseMatches) {
                        If ($BaseNameMatch.Version -lt $GPLink.Version) {
                            ol v "The lower versioned GPO '$($BaseNameMatch.Name)' will be unlinked"
                            $Unlink += $BaseNameMatch.Name
                        } 
                        ElseIf ($BaseNameMatch.Version -gt $GPLink.Version) {
                            ol w "The higher versioned GPO '$($BaseNameMatch.Name)' is already linked"
                            Throw "The higher versioned GPO '$($BaseNameMatch.Name)' is already linked"
                        }
                    }
                    # If any items in $Unlink, add the array as property 'Unlink' 
                    If ($Unlink.Count -gt 0) {
                        $GPLink | Add-Member -MemberType NoteProperty -Name 'Unlink' -Value $Unlink 
                    }

                }

                # Remove existing GPLink, if Links for lower versioned GPOs exist
                ForEach ($LinkToRemove in $GPLink.Unlink) {
                    ol i @('Unlinking', "$LinkToRemove")

                    $RemoveLinkArgumentList = @($GPOLinkObject.Path, $LinkToRemove, $Server)
                    $InvokeRemoveLinkParams = @{
                        ScriptBlock  = $DryAD_SB_GPLink_Remove
                        ArgumentList = $RemoveLinkArgumentList
                    }
                    If ($PSCmdLet.ParameterSetName -eq 'Remote') {
                        $InvokeRemoveLinkParams += @{
                            Session = $PSSession
                        }
                    }
                    $RemoveLinkRet = Invoke-Command @InvokeRemoveLinkParams 
                    
                    If ($RemoveLinkRet[0] -eq $True) {
                        ol s "Successfully removed link for GPO '$LinkToRemove'"
                    }
                    Else {
                        Throw $RemoveLinkRet[1]
                    }
                }

                # Finally, we're ready to set the new GPO Link
                ol i @('GPO', "$($GPLink.Name)")

                $NewLinkArgumentList = @(
                    $GPOLinkObject.Path,
                    $GPLink.Name,
                    $GPLink.Order,
                    $LinkEnabled,
                    $Enforced,
                    $Server
                )

                $InvokeNewLinkParams = @{
                    ScriptBlock  = $DryAD_SB_GPLink_New
                    ArgumentList = $NewLinkArgumentList
                }

                If ($PSCmdLet.ParameterSetName -eq 'Remote') {
                    $InvokeNewLinkParams += @{
                        Session = $PSSession
                    }
                }
                $NewLinkRet = Invoke-Command @InvokeNewLinkParams
                
                If ($NewLinkRet[0] -eq $True) {
                    ol s 'GPO Linked'
                }
                Else {
                    ol f 'GPO Link failed'
                    Throw $NewLinkRet[1]
                }
            }
            Catch {
                $PSCmdLet.ThrowTerminatingError($_)
            }
            Finally {
                # remove variables 
                @('CurrentlyLinkedMatch',
                    'BaseName',
                    'Version',
                    'CurrentlyLinkedBaseMatches',
                    'Unlink',
                    'LinkEnabled',
                    'Enforced').ForEach({
                        Remove-Variable -Name $_ -ErrorAction Ignore
                    })
            }
        }
    }
    Catch {
        $PSCmdLet.ThrowTerminatingError($_)
    }
}
