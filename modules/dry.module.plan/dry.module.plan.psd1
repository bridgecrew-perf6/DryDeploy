<# 
    This module contains functions to resolve, get, modify and show a DryDeploy 
    Plan.  

    Copyright (C) 2021  Bjorn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/DryDeploy/main/LICENSE
    
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

@{

# Script module or binary module file associated with this manifest.
RootModule = 'dry.module.plan.psm1'

# Version number of this module.
ModuleVersion = '0.2'

# Supported PSEditions
CompatiblePSEditions = 'Desktop','Core'

# ID used to uniquely identify this module
GUID = 'c65fed31-bc35-41b9-a15f-05feed3bdc7c'

# Author of this module
Author = 'bjoernf73'

# Company or vendor of this module
# CompanyName = ''

# Copyright statement for this module
Copyright = '(c) 2021 bjoernf73. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Plan functionality of DryDeploy'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = 'Amd64'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules       = @(
    @{
        ModuleName    = "dry.module.log"; 
        ModuleVersion = "0.0.4"; 
        Guid          = "267d805a-196e-4d87-8d73-4ef45df727c3"
    }
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module. 
ScriptsToProcess = @(
    "classes\dry.module.plan.class.planfilter.ps1",
    "classes\dry.module.plan.class.network.ps1",
    "classes\dry.module.plan.class.resource.ps1",
    "classes\dry.module.plan.class.resources.ps1",
    "classes\dry.module.plan.class.action_and_plan.ps1"
)

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-DryPlan',
    'New-DryPlan',
    'Set-DryPlan',
    'Show-DryActionStart',
    'Show-DryActionEnd',
    'Show-DryPlan'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://raw.githubusercontent.com/bjoernf73/DryDeploy/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/bjoernf73/DryDeploy'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = 'I support stuff now'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}