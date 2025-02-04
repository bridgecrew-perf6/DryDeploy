﻿<#  
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
Function Get-DryADOUPathFromAlias {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$Alias,

        [Parameter(Mandatory)]
        [Array]$OUs,

        [Parameter(Mandatory)]
        [String]$Scope,

        [Parameter()]
        [String]$Child
    )

    $ReferencedOU = $OUs | Where-Object {  
        $_.Alias -eq $Alias
    }

    ol d 'Alias', "$Alias"
    ol d 'Scope', "$Scope"
    ol d 'Child', "$Child"

    If ($Null -eq $ReferencedOU) {
        ol e @('Unable to resolve OU from Alias', 'No OUs found')
        Throw "Unable to find OU for Alias '$Alias': No references found"
    } 

    If ($ReferencedOU -is [Array]) {
        ol e @('Unable to resolve OU from Alias', 'Multiple OUs found')
        Throw "Unable to find single OU for Alias '$Alias': Multiple references found"
    }
    
    $Path = $ReferencedOU.Path
    If ($Null -eq $Path) {
        ol e "Found OU '$($OU.Alias)', but it contains no path"
        Throw "Found OU '$($OU.Alias)', but it contains no path"
    }

    # If child, add that
    If ($Child) {
        $Path = $Path + '/' + $Child -replace '//', '/'
    }

    ol v @("Alias '$Alias'", "$Path")
    $Path
}
