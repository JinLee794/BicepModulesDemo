#region helper

<#
.SYNOPSIS
If a deployment failed, get its error message

.DESCRIPTION
If a deployment failed, get its error message based on the deployment name in the given scope

.PARAMETER DeploymentScope
Mandatory. The scope to fetch the deployment from (e.g. resourcegroup, tenant,...)

.PARAMETER DeploymentName
Mandatory. The name of the deployment to search for (e.g. 'storageAccounts-20220105T0701282538Z')

.PARAMETER ResourceGroupName
Optional. The resource group to search the deployment in, if the scope is 'resourcegroup'

.EXAMPLE
Get-ErrorMessageForScope -DeploymentScope 'resourcegroup' -DeploymentName 'storageAccounts-20220105T0701282538Z' -ResourceGroupName 'validation-rg'

Get the error message of any failed deployment into resource group 'validation-rg' that has the name 'storageAccounts-20220105T0701282538Z'

.EXAMPLE
Get-ErrorMessageForScope -DeploymentScope 'subscription' -DeploymentName 'resourcegroups-20220106T0401282538Z'

Get the error message of any failed deployment into the current subscription that has the name 'storageAccounts-20220105T0701282538Z'
#>
function Get-ErrorMessageForScope {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $DeploymentScope,

        [Parameter(Mandatory)]
        [string] $DeploymentName,

        [Parameter(Mandatory = $false)]
        [string] $ResourceGroupName = ''
    )

    switch ($deploymentScope) {
        'resourcegroup' {
            $deployments = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName
            break
        }
        'subscription' {
            $deployments = Get-AzDeploymentOperation -DeploymentName $deploymentName
            break
        }
        'managementgroup' {
            $deployments = Get-AzManagementGroupDeploymentOperation -DeploymentName $deploymentName
            break
        }
        'tenant' {
            $deployments = Get-AzTenantDeploymentOperation -DeploymentName $deploymentName
            break
        }
    }
    if ($deployments) {
        return ($deployments | Where-Object { $_.ProvisioningState -ne 'Succeeded' }).StatusMessage
    }
}

<#
.SYNOPSIS
Run a template deployment using a given parameter file

.DESCRIPTION
Run a template deployment using a given parameter file.
Works on a resource group, subscription, managementgroup and tenant level

.PARAMETER templateFilePath
Mandatory. The path to the deployment file

.PARAMETER parameterFilePath
Optional. Path to the parameter file from root. Can be a single file, multiple files, or directory that contains (.json) files.

.PARAMETER location
Mandatory. Location to test in. E.g. WestEurope

.PARAMETER resourceGroupName
Optional. Name of the resource group to deploy into. Mandatory if deploying into a resource group (resource group level)

.PARAMETER subscriptionId
Optional. ID of the subscription to deploy into. Mandatory if deploying into a subscription (subscription level) using a Management groups service connection

.PARAMETER managementGroupId
Optional. Name of the management group to deploy into. Mandatory if deploying into a management group (management group level)

.PARAMETER additionalTags
Optional. Provde a Key Value Pair (Object) that will be appended to the Parameter file tags. Example: @{myKey = 'myValue',myKey2 = 'myValue2'}.

.PARAMETER additionalParameters
Optional. Additional parameters you can provide with the deployment. E.g. @{ resourceGroupName = 'myResourceGroup' }

.PARAMETER retryLimit
Optional. Maximum retry limit if the deployment fails. Default is 3.

.PARAMETER doNotThrow
Optional. Do not throw an exception if it failed. Still returns the error message though

.EXAMPLE
New-DeploymentWithParameterFile -templateFilePath 'C:/KeyVault/deploy.json' -parameterFilePath 'C:/KeyVault/.parameters/parameters.json' -location 'WestEurope' -resourceGroupName 'aLegendaryRg'

Deploy the deploy.json of the KeyVault module with the parameter file 'parameters.json' using the resource group 'aLegendaryRg' in location 'WestEurope'

.EXAMPLE
New-DeploymentWithParameterFile -templateFilePath 'C:/ResourceGroup/deploy.json' -location 'WestEurope'

Deploy the deploy.json of the ResourceGroup module without a parameter file in location 'WestEurope'
#>
function New-DeploymentWithParameterFile {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string] $templateFilePath,

        [Parameter(Mandatory = $false)]
        [string] $parameterFilePath,

        [Parameter(Mandatory = $false)]
        [string] $resourceGroupName = '',

        [Parameter(Mandatory)]
        [string] $location,

        [Parameter(Mandatory = $false)]
        [string] $subscriptionId,

        [Parameter(Mandatory = $false)]
        [string] $managementGroupId,

        [Parameter(Mandatory = $false)]
        [PSCustomObject] $additionalTags,

        [Parameter(Mandatory = $false)]
        [Hashtable] $additionalParameters,

        [Parameter(Mandatory = $false)]
        [switch] $doNotThrow,

        [Parameter(Mandatory = $false)]
        [int]$retryLimit = 3
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        # Load helper
        . (Join-Path (Get-Item -Path $PSScriptRoot).parent.FullName 'sharedScripts' 'Get-ScopeOfTemplateFile.ps1')
    }

    process {
        $moduleName = Split-Path -Path (Split-Path $templateFilePath -Parent) -LeafBase

        # Generate a valid deployment name. Must match ^[-\w\._\(\)]+$
        do {
            $deploymentName = "$moduleName-$(-join (Get-Date -Format yyyyMMddTHHMMssffffZ)[0..63])"
        } while ($deploymentName -notmatch '^[-\w\._\(\)]+$')

        Write-Verbose "Deploying with deployment name [$deploymentName]" -Verbose

        $DeploymentInputs = @{
            DeploymentName = $deploymentName
            TemplateFile   = $templateFilePath
            Verbose        = $true
            ErrorAction    = 'Stop'
        }

        # Parameter file provided yes/no
        if (-not [String]::IsNullOrEmpty($parameterFilePath)) {
            $DeploymentInputs['TemplateParameterFile'] = $parameterFilePath
        }

        # Additional parameter object provided yes/no
        if ($additionalParameters) {
            $DeploymentInputs += $additionalParameters
        }

        # Additional tags provides yes/no
        # Append tags to parameters if resource supports them (all tags must be in one object)
        if ($additionalTags) {

            # Parameter tags
            if (-not [String]::IsNullOrEmpty($parameterFilePath)) {
                $parameterFileTags = (ConvertFrom-Json (Get-Content -Raw -Path $parameterFilePath) -AsHashtable).parameters.tags.value
            }
            if (-not $parameterFileTags) { $parameterFileTags = @{} }

            # Pipeline tags
            if ($additionalTags) { $parameterFileTags += $additionalTags } # If additionalTags object is provided, append tag to the resource

            # Overwrites parameter file tags parameter
            Write-Verbose ("additionalTags: $(($additionalTags) ? ($additionalTags | ConvertTo-Json) : '[]')")
            $DeploymentInputs += @{Tags = $parameterFileTags }
        }

        #######################
        ## INVOKE DEPLOYMENT ##
        #######################
        $deploymentScope = Get-ScopeOfTemplateFile -TemplateFilePath $templateFilePath
        [bool]$Stoploop = $false
        [int]$retryCount = 1

        do {
            try {
                switch ($deploymentScope) {
                    'resourcegroup' {
                        if ($subscriptionId) {
                            $Context = Get-AzContext -ListAvailable | Where-Object Subscription -Match $subscriptionId
                            if ($Context) {
                                $null = $Context | Set-AzContext
                            }
                        }
                        if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction 'SilentlyContinue')) {
                            if ($PSCmdlet.ShouldProcess("Resource group [$resourceGroupName] in location [$location]", 'Create')) {
                                New-AzResourceGroup -Name $resourceGroupName -Location $location
                            }
                        }
                        if ($PSCmdlet.ShouldProcess('Resource group level deployment', 'Create')) {
                            $res = New-AzResourceGroupDeployment @DeploymentInputs -ResourceGroupName $resourceGroupName
                        }
                        break
                    }
                    'subscription' {
                        if ($subscriptionId) {
                            $Context = Get-AzContext -ListAvailable | Where-Object Subscription -Match $subscriptionId
                            if ($Context) {
                                $null = $Context | Set-AzContext
                            }
                        }
                        if ($PSCmdlet.ShouldProcess('Subscription level deployment', 'Create')) {
                            $res = New-AzSubscriptionDeployment @DeploymentInputs -Location $location
                        }
                        break
                    }
                    'managementgroup' {
                        if ($PSCmdlet.ShouldProcess('Management group level deployment', 'Create')) {
                            $res = New-AzManagementGroupDeployment @DeploymentInputs -Location $location -ManagementGroupId $managementGroupId
                        }
                        break
                    }
                    'tenant' {
                        if ($PSCmdlet.ShouldProcess('Tenant level deployment', 'Create')) {
                            $res = New-AzTenantDeployment @DeploymentInputs -Location $location
                        }
                        break
                    }
                    default {
                        throw "[$deploymentScope] is a non-supported template scope"
                        $Stoploop = $true
                    }
                }
                $Stoploop = $true
            } catch {
                if ($retryCount -ge $retryLimit) {
                    if ($doNotThrow) {

                        # In case a deployment failes but not throws an exception (i.e. the exception message is empty) we try to fetch it via the deployment name
                        if ([String]::IsNullOrEmpty($PSitem.Exception.Message)) {
                            $errorInputObject = @{
                                DeploymentScope   = $deploymentScope
                                DeploymentName    = $deploymentName
                                ResourceGroupName = $resourceGroupName
                            }
                            $exceptionMessage = Get-ErrorMessageForScope @errorInputObject
                        } else {
                            $exceptionMessage = $PSitem.Exception.Message
                        }

                        return @{
                            DeploymentName = $deploymentName
                            Exception      = $exceptionMessage
                        }
                    } else {
                        throw $PSitem.Exception.Message
                    }
                    $Stoploop = $true
                } else {
                    Write-Verbose "Resource deployment Failed.. ($retryCount/$retryLimit) Retrying in 5 Seconds.. `n"
                    Write-Verbose ($PSitem.Exception.Message | Out-String) -Verbose
                    Start-Sleep -Seconds 5
                    $retryCount++
                }
            }
        }
        until ($Stoploop -eq $true -or $retryCount -gt $retryLimit)

        Write-Verbose 'Result' -Verbose
        Write-Verbose '------' -Verbose
        Write-Verbose ($res | Out-String) -Verbose
        return @{
            deploymentName   = $deploymentName
            deploymentOutput = $res.Outputs
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
#endregion

<#
.SYNOPSIS
Run a template deployment using a given parameter file

.DESCRIPTION
Run a template deployment using a given parameter file.
Works on a resource group, subscription, managementgroup and tenant level

.PARAMETER templateFilePath
Mandatory. The path to the deployment file

.PARAMETER parameterFilePath
Optional. Path to the parameter file from root. Can be a single file, multiple files, or directory that contains (.json) files.

.PARAMETER location
Mandatory. Location to test in. E.g. WestEurope

.PARAMETER resourceGroupName
Optional. Name of the resource group to deploy into. Mandatory if deploying into a resource group (resource group level)

.PARAMETER subscriptionId
Optional. ID of the subscription to deploy into. Mandatory if deploying into a subscription (subscription level) using a Management groups service connection

.PARAMETER managementGroupId
Optional. Name of the management group to deploy into. Mandatory if deploying into a management group (management group level)

.PARAMETER additionalTags
Optional. Provde a Key Value Pair (Object) that will be appended to the Parameter file tags. Example: @{myKey = 'myValue',myKey2 = 'myValue2'}.

.PARAMETER additionalParameters
Optional. Additional parameters you can provide with the deployment. E.g. @{ resourceGroupName = 'myResourceGroup' }

.PARAMETER retryLimit
Optional. Maximum retry limit if the deployment fails. Default is 3.

.PARAMETER doNotThrow
Optional. Do not throw an exception if it failed. Still returns the error message though

.EXAMPLE
New-ModuleDeployment -templateFilePath 'C:/KeyVault/deploy.json' -parameterFilePath 'C:/KeyVault/.parameters/parameters.json' -location 'WestEurope' -resourceGroupName 'aLegendaryRg'

Deploy the deploy.json of the KeyVault module with the parameter file 'parameters.json' using the resource group 'aLegendaryRg' in location 'WestEurope'

.EXAMPLE
New-ModuleDeployment -templateFilePath 'C:/ResourceGroup/deploy.json' -parameterFilePath 'C:/ResourceGroup/.parameters/parameters.json' -location 'WestEurope'

Deploy the deploy.json of the ResourceGroup module with the parameter file 'parameters.json' in location 'WestEurope'
#>
function New-ModuleDeployment {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string] $templateFilePath,

        [Parameter(Mandatory = $false)]
        [string[]] $parameterFilePath,

        [Parameter(Mandatory)]
        [string] $location,

        [Parameter(Mandatory = $false)]
        [string] $resourceGroupName = '',

        [Parameter(Mandatory = $false)]
        [string] $subscriptionId,

        [Parameter(Mandatory = $false)]
        [string] $managementGroupId,

        [Parameter(Mandatory = $false)]
        [Hashtable] $additionalParameters,

        [Parameter(Mandatory = $false)]
        [PSCustomObject] $additionalTags,

        [Parameter(Mandatory = $false)]
        [switch] $doNotThrow,

        [Parameter(Mandatory = $false)]
        [int]$retryLimit = 3
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        ## Assess Provided Parameter Path
        if ((-not [String]::IsNullOrEmpty($parameterFilePath)) -and (Test-Path -Path $parameterFilePath -PathType 'Container') -and $parameterFilePath.Length -eq 1) {
            ## Transform Path to Files
            $parameterFilePath = Get-ChildItem $parameterFilePath -Recurse -Filter *.json | Select-Object -ExpandProperty FullName
            Write-Verbose "Detected Parameter File(s)/Directory - Count: `n $($parameterFilePath.Count)"
        }

        ## Iterate through each file
        $deploymentInputObject = @{
            templateFilePath     = $templateFilePath
            additionalTags       = $additionalTags
            additionalParameters = $additionalParameters
            location             = $location
            resourceGroupName    = $resourceGroupName
            subscriptionId       = $subscriptionId
            managementGroupId    = $managementGroupId
            doNotThrow           = $doNotThrow
            retryLimit           = $retryLimit
        }
        if ($parameterFilePath) {
            if ($parameterFilePath -is [array]) {
                $deploymentResult = [System.Collections.ArrayList]@()
                foreach ($path in $parameterFilePath) {
                    if ($PSCmdlet.ShouldProcess("Deployment for parameter file [$parameterFilePath]", 'Trigger')) {
                        $deploymentResult += New-DeploymentWithParameterFile @deploymentInputObject -parameterFilePath $path
                    }
                }
                return $deploymentResult
            } else {
                if ($PSCmdlet.ShouldProcess("Deployment for single parameter file [$parameterFilePath]", 'Trigger')) {
                    return New-DeploymentWithParameterFile @deploymentInputObject -parameterFilePath $parameterFilePath
                }
            }
        } else {
            if ($PSCmdlet.ShouldProcess('Deployment without parameter file', 'Trigger')) {
                return New-DeploymentWithParameterFile @deploymentInputObject
            }
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
