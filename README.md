---
external help file: -help.xml
Module Name:
online version:
schema: 2.0.0
---

# DryDeploy.ps1

## SYNOPSIS
DryDeploy is a bridge between deployment technologies.

A complete autodeploy of an information system may require you 
to use a variety of technologies.
For instance, DSC (Desired 
State Configuration) is great for configuring Windows roles, but 
does not operate well (or at all) against your platform provider.
You may need to use Packer to automate customization of your templates, 
and Terraform to instantiate them. 

Common for DSC, Terraform and Packer is that: 
 - you create one or more file containing your configuration, using
 variables for environment specific values and secrets
 - when you deploy, you suppply the tool with the path to the config,
 and all the variables that the configuration needs. 

 Manually, this is a pretty tedious task, given that you must do this 
 for every action that configures some part of your role, for every 
 role that your system module, or information system, consists of. 
 Moreover, if you first took the time to put everything in code - 
 shouldn't that enable you to just 'click play' to deploy everything?

 DryDeploy does.
And all you need is a client.
 
 
 Define your networks, resources (instances of roles) and platform(s)
 (the CoreConfig) in an environment confguration repository.
You may 
 also add any set of user defined data and data structure to the 
 environment configuration (the UserConfig). 
 
 Each action of a role is provided with a set of expressions that 
 resolves values from that configuration.
The set is then passed to 
 the technology that performs the action, be it Terraform, Packer, 
 DSC or other.

 ...one command to Plan...
   
   .\DryDeploy.ps1 -Plan
 
 ...and one to Apply....

   .\DryDeploy.ps1 -Apply
 
 If something fails, edit your code, and -Apply again.
DryDeploy 
 retries the failed Action and continues to Apply the rest of the 
 Plan.

## SYNTAX

### ShowPlan (Default)
```
DryDeploy.ps1 [-ShowDeselected] [<CommonParameters>]
```

### Init
```
DryDeploy.ps1 [-Init] [<CommonParameters>]
```

### Plan
```
DryDeploy.ps1 [-Plan] [-Actions <String[]>] [-ExcludeActions <String[]>] [-BuildSteps <Int32[]>]
 [-ExcludeBuildSteps <Int32[]>] [-Resources <String[]>] [-ExcludeResources <String[]>] [-Roles <String[]>]
 [-ExcludeRoles <String[]>] [-Phases <Int32[]>] [-ExcludePhases <Int32[]>] [-NoLog] [-ShowDeselected]
 [-CmTrace] [<CommonParameters>]
```

### Apply
```
DryDeploy.ps1 [-Apply] [-Actions <String[]>] [-ExcludeActions <String[]>] [-BuildSteps <Int32[]>]
 [-ExcludeBuildSteps <Int32[]>] [-Resources <String[]>] [-ExcludeResources <String[]>] [-Roles <String[]>]
 [-ExcludeRoles <String[]>] [-Phases <Int32[]>] [-ExcludePhases <Int32[]>] [-ActionParams <Hashtable>] [-NoLog]
 [-KeepConfigFiles] [-DestroyOnFailedBuild] [-ShowAllErrors] [-ShowPasswords] [-ShowStatus]
 [-SuppressInteractivePrompts] [-IgnoreDependencies] [-Step] [-Quit] [-CmTrace] [-Force] [<CommonParameters>]
```

### SetConfig
```
DryDeploy.ps1 [-EnvConfig <String>] [-ModuleConfig <String>] [<CommonParameters>]
```

### GetConfig
```
DryDeploy.ps1 [-GetConfig] [<CommonParameters>]
```

## DESCRIPTION
DryDeploy prepares your deployment platform (-Init), stores paths to a 
configuration combination of an environment configuration (EnvConfig)
and a module configuration (ModuleConfig), creates a Plan of Actions 
to perform based on the configurations and any filters specified (-Plan), 
and applies the plan in the configured order (-Apply).
Run DryDeploy
parameterless to show the status of the current Plan. 

Dryeploy needs 2 configuration repositories: 

 - EnvConfig: must contain the "CoreConfig" - information of your 
   environment; network information, target platforms (cloud, on-prem, 
   hybrid), and all the resources (instances of roles).
It can also
   contain a "UserConfig" which is any data you can put in a json
   or yaml.
Lastly, it may contain "BaseConfig", which contains shared,
   generic configurations which every (or selected) instances of an 
   operating system should invoke.
 

 - ModuleConfig: Contains Roles and a Build.
Roles are the blueprint
   configuration of some type of resource, be it a Windows domain
   controller, a linux gitlab server, or simply a container instance.
   A module may contain one or multiple roles, and roles may be re-used 
   in multiple system modules.
The Role contain the configuration files
   used by any Action that the role build addresses.
It also contain a
   set of expressions that when run against the EnvConfig, they resolve 
   the variable values that in turn will be passed to the technology 
   behind the Action (i.e.
Terraform, Packer, DSC, SaltStack and so on)
   The Build defines how the module is built.
It contains 
      1.
the order in which Roles are deployed
      2.
the order in which Actions of the Roles are deployed
   Actions of a role may 'depend on' Actions of other roles, so that 
   when you -Plan, the execution of the dependent Action is delayed 
   until after the action it depends on.

## EXAMPLES

### EXAMPLE 1
```
.\DryDeploy.ps1 -Init
```

Will prepare your system for deployment.
Installs Choco, Git, 
Packer, downloads and installs modules, and dependent git repos.
Make sure to elevate your PowerShell for this one - it will fail
if not

### EXAMPLE 2
```
.\DryDeploy.ps1 -ModuleConfig ..\ModuleConfigs\MyModule -EnvConfig ..\EnvConfigs\MyEnvironment
```

Creates a configuration combination of a module configuration and
an environment configuration.
The combination (the "ConfigCombo") 
is stored and used on every subsequent run until you invoke the 
SetConfig parameterset again.

### EXAMPLE 3
```
.\DryDeploy.ps1 -Plan
```

Will create a full plan for all resources in the configuration that
is of a role that matches roles in your ModuleConfig

### EXAMPLE 4
```
.\DryDeploy.ps1
```

Displays the current Plan

### EXAMPLE 5
```
.\DryDeploy.ps1 -Plan -Resources dc,ca
```

Creates a partial plan, containing only Resources whos name is 
or matches "dc*" or "ca*"

### EXAMPLE 6
```
.\DryDeploy.ps1 -Plan -Resources dc,ca -Actions terra,ad
```

Creates a partial plan, containing only Resources whos name is 
or match "dc*" or "ca*", with only Actions whos name is or 
matches "terra*" (for instance "terra.run") or "ad*" (for instance 
"ad.import")

### EXAMPLE 7
```
.\DryDeploy.ps1 -Plan -ExcludeResources DC,DB
```

Creates a partial plan, excluding any Resource whos name is or 
matches "DC*" or "DB*"

### EXAMPLE 8
```
.\DryDeploy.ps1 -Apply
```

Applies the current Plan.

### EXAMPLE 9
```
.\DryDeploy.ps1 -Apply -Force
```

Applies the current Plan, destroying any resource with the same 
identity as the resource you are creating.

### EXAMPLE 10
```
.\DryDeploy.ps1 -Apply -Resources ca002 -Actions ad.import
```

Applies only actions of the Plan where the Resources name is or 
matches "ca002*", and the name of the Action that is or matches 
"ad.import"

### EXAMPLE 11
```
$Config = .\DryDeploy.ps1 -GetConfig
```

Returns the configuration object, and assigns it to the variable 
'$Config' so you may inspect it's content 'offline'

## PARAMETERS

### -Init
Inistializes the local system for package management, and installs 
all dependencies for DryDeploy and for the selected system module.
Supports git-repos-as-PowerShell-modules, chocolatey packages, nuget
modules, windows features, optional features and so on.

```yaml
Type: SwitchParameter
Parameter Sets: Init
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Plan
Create or modify a Plan.
Use alone for a full Plan, or with any 
filter to limit the Actions to include in the Plan (-Actions, 
-ExcludeActions, -BuildSteps, -ExcludeBuildSteps, -Resources, 
-ExcludeResources, -Roles, -ExcludeRoles, -Phases, -ExcludePhases)

```yaml
Type: SwitchParameter
Parameter Sets: Plan
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Apply
Applies the Plan.
Use alone to to Apply the full Plan, or with
any filter to only Apply a limited set of planned actions (-Actions, 
-ExcludeActions, -BuildSteps, -ExcludeBuildSteps, -Resources, 
-ExcludeResources, -Roles, -ExcludeRoles, -Phases, -ExcludePhases)

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Actions
Array of one or more Actions to include.
All others are excluded. 
If not specified, Actions are disregarded from the filter.
Supports 
tab-completion and partial match ('ter' will match Action 'terra.run')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeActions
Array of one or more Actions to exclude.
All others are included. 
If not specified, Actions are disregarded from the filter.Supports 
tab-completion and partial match ('ter' will match Action 'terra.run')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BuildSteps
Array of one or more BuildSteps to include.
All others are 
excluded.
If not specified, BuildSteps are disregarded from 
the filter.
Specify as digits, or sets of digits, like 3 or 
3,4,5 or (3..5) for a range

```yaml
Type: Int32[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeBuildSteps
Array of one or more BuildSteps to exclude.
All others are 
included.
If not specified, BuildSteps are disregarded from 
the filter.
Specify as digits, or sets of digits, like 3 or 
3,4,5 or (3..5) for a range

```yaml
Type: Int32[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resources
Array of one or more Resource names to include.
All others are 
excluded.
If not specified, Resources are disregarded from the 
filter.
Supports tab-completion and partial match ('dc' will 
match Resource 'dc1-s5-d')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeResources
Array of one or more Resource names to exclude.
All others are 
included.
If not specified, Resources are disregarded from the 
filter.
Supports partial match ('dc' will match Resource 'dc1-s5-d')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Roles
Array of one or more Role names to include.
All others are 
excluded.
If not specified, Roles are disregarded from the 
filter.
Supports tab-completion and partial match ('dc' will 
match Role 'dc-domctrl-froot')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeRoles
Array of one or more Role names to exclude.
All others are 
included.
If not specified, Roles are disregarded from the 
filter.
Supports tab-completion and partial match ('dc' will 
match Role 'dc-domctrl-froot')

```yaml
Type: String[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Phases
Array of one or more Phases (of any Action) to include.
All other 
Phases (and non-phased actions) are excluded.
If not specified, 
Phases are disregarded from the filter

```yaml
Type: Int32[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludePhases
Array of one or more Phases (of any Action) to exclude.
All other 
Phases (and non-phased actions) are included.
If not specified, 
Phases are disregarded from the filter

```yaml
Type: Int32[]
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnvConfig
Path to the directory of an environment configuration.
Use to  
set the configuration combination (ConfigCombo).
It will be 
stored, and used implicitly until you change it.

```yaml
Type: String
Parameter Sets: SetConfig
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleConfig
Path to the directory of a system module configuration.
Use to 
set the configuration combination (ConfigCombo).
It will be 
stored, and used implicitly until you change it.

```yaml
Type: String
Parameter Sets: SetConfig
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActionParams
HashTable that will be sent to the Action function.
Useful during 
development, for instance if the receiving action function 
supports a parameter to specify a limited set of tasks to do.

```yaml
Type: Hashtable
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetConfig
During -Plan and -Apply, selected configurations from the current 
Environment and Module are combined into one configuration object.
Run -GetConfig to just return this configuration object, and then 
quit.
Assign the output to a variable to examine the configuration.

```yaml
Type: SwitchParameter
Parameter Sets: GetConfig
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoLog
By default, a log file will be written.
If you're opposed to that, 
use -NoLog.

```yaml
Type: SwitchParameter
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepConfigFiles
Will not delete temporary configuration files at end of Action. 
However, upon running the action again, if the target temp 
is populated with files, those files will still be deleted.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestroyOnFailedBuild
If your run builds something, for instance with packer, that 
artifact will be kept if the build fails, so you may examine 
it's failed state.
Use to destroy the fail-built artifact instead"

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowAllErrors
If an exception occurs, I try to display the terminating error. 
If -ShowAllErrors, I'll show all errors in the $Error variable.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowPasswords
Credentials are resolved from the Credentials node of the 
configuration by the function Get-DryCredential.
If 
-ShowPasswords, clear text passwords will be output to screen 
by that function.
Use with care

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowStatus
Will show detailed status messages for each individual 
configuration task in some Actions.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowDeselected
When you -Plan, or run without any other params, just to show
the Plan, only Actions selected in the Plan will be displayed. 
If you do -ShowDeselected, the deselected Actions will be 
displayed in a table below your active Plan.

```yaml
Type: SwitchParameter
Parameter Sets: ShowPlan, Plan
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressInteractivePrompts
Will suppress any interactive prompt.
Useful when running in a 
CI/CD pipeline.
When for instance a credential is not found in 
the configuration's credentials node, an interactive prompt will 
prompt for it.
Use to suppress that prompt, and throw an error 
instead

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDependencies
Ignores any dependency for both ModuleConfig and

DD itself

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Step
When you -Apply, you may -Step to step through each Action with-
out automatically jumping to the next.
This will require you to
interactively confirm each jump to next Action.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quit
When you -Apply, you may -Quit to make the script quit after 
every Action.
Useful for CI/CD Pipelines, since the run may 
be devided into blocks that are visually pleasing.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CmTrace
Will open the log file in cmtrace som you may follow the output-
to-log interactively.
You will need CMTrace.exe on you system 
and in path

```yaml
Type: SwitchParameter
Parameter Sets: Plan, Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Will destroy existing resources.
Careful.

```yaml
Type: SwitchParameter
Parameter Sets: Apply
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
