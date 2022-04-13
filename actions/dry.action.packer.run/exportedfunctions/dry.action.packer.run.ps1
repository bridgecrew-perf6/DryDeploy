function dry.action.packer.run {
    [CmdletBinding()]  
    param (
        [Parameter(Mandatory,HelpMessage="The resolved action object")]
        [PSObject]$Action,

        [Parameter(Mandatory,HelpMessage="The resolved resource object")]
        [PSObject]$Resource,

        [Parameter(Mandatory,HelpMessage="The resolved environment configuration object")]
        [PSObject]$Configuration,

        [Parameter(Mandatory,HelpMessage="ResourceVariables contains resolved variable values from the configurations common_variables and resource_variables combined")]
        [System.Collections.Generic.List[PSObject]]$ResourceVariables,

        [Parameter(Mandatory=$False,HelpMessage="Hash directly from the command line to be added as parameters to the function that iniates the action")]
        [HashTable]$ActionParams
    )
    try {

        # [String]$ConfigTargetPath = "$ConfigurationTargetPath\ProvisionDSC\$($Action.Phase)\"
        $RolePath = "$($Resource.RolePath)"
        $ConfigurationTargetPath = "$($Resource.ConfigurationTargetPath)"


        # $PackerFilePath is the path to the packer config file
        if ($Action.Phase -ge 1) {
            $PackerFilePath = $RolePath + "\packer.run\$($Action.Phase)\PackerConfig.json"

            # $ConfigFilePath is the path to the file describing which files will be copied to the working directory, 
            # and what actions to perfomed on those files, for instance string replacement
            $ConfigFilePath = $RolePath + "\packer.run\$($Action.Phase)\Config.json"

            # Directory into which configuration files are written
            [String]$ConfigTargetPath = "$ConfigurationTargetPath\packer.run\$($Action.Phase)\"
        }
        else {
            $PackerFilePath = $RolePath + "\packer.run\PackerConfig.json"

            # $ConfigFilePath is the path to the file describing which files will be copied to the working directory, 
            # and what actions to perfomed on those files, for instance string replacement
            $ConfigFilePath = $RolePath + '\packer.run\Config.json'

            # Directory into which configuration files are written
            [String]$ConfigTargetPath = "$ConfigurationTargetPath\packer.run\"
        }
        
        if (Test-Path -Path $ConfigTargetPath -ErrorAction SilentlyContinue) {
            Remove-Item -Path $ConfigTargetPath -Recurse -Force -Confirm:$false | 
            Out-Null
        }

        
        New-Item -Path $ConfigTargetPath -ItemType Directory -Confirm:$false -Force | 
        Out-Null

        # The action object must contain one, but may contain more, credential referrals
        $Credentials = [System.Collections.Generic.List[PSObject]]::New()
        
        # Add all credentials to the $Credentials collection
        $CredIndex = 1
        while ($Action.credentials."credential$CredIndex") {
            $Credentials.Add([PSObject]@{
                "credential$CredIndex" = Get-DryCredential -Alias ($Action.credentials."credential$CredIndex") -EnvConfig $GLOBAL:EnvConfigName
            })
            $CredIndex++
        }

        # Build up a hash to splat to Invoke-DryPackerDeployment
        $InvokeDryPackerDeploymentParams = @{
            PackerFile       = $PackerFilePath
            ConfigFile       = $ConfigFilePath
            Resource         = $Resource
            Variables        = $ResourceVariables
            Credentials      = $Credentials
            WorkingDirectory = $ConfigTargetPath
        }
        Invoke-DryPackerDeployment @InvokeDryPackerDeploymentParams
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        # Remove temporary files
        if ($GLOBAL:KeepConfigFiles) {
            ol i @('Keeping ConfigFiles in',"$ConfigTargetPath")
        }
        else {
            ol i @('Removing ConfigFiles from',"$ConfigTargetPath")
            Remove-Item -Path $ConfigTargetPath -ErrorAction Ignore -Recurse -Force -Confirm:$false
        }
        ol i "Action 'packer.run' is finished" -sh
    }
}