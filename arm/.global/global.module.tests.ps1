#Requires -Version 7

param (
    [array] $moduleFolderPaths = ((Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Directory -Force).FullName | Where-Object {
        (Get-ChildItem $_ -File -Depth 0 -Include @('deploy.json', 'deploy.bicep') -Force).Count -gt 0
        })
)

$script:Settings = Get-Content -Path (Join-Path $PSScriptRoot '..\..\settings.json') | ConvertFrom-Json
$script:RGdeployment = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
$script:Subscriptiondeployment = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#'
$script:MGdeployment = 'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#'
$script:Tenantdeployment = 'https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#'
$script:moduleFolderPaths = $moduleFolderPaths
$script:moduleFolderPathsFiltered = $moduleFolderPaths | Where-Object {
    (Split-Path $_ -Leaf) -notin @( 'AzureNetappFiles', 'TrafficManager', 'PrivateDnsZones', 'ManagementGroups') }

# Import any helper function used in this test script
Import-Module (Join-Path $PSScriptRoot 'shared\helper.psm1')

Describe 'File/folder tests' -Tag Modules {

    Context 'General module folder tests' {

        $moduleFolderTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            $moduleFolderTestCases += @{
                moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]
                moduleFolderPath = $moduleFolderPath
            }
        }

        It '[<moduleFolderName>] Module should contain a [deploy.json/deploy.bicep] file' -TestCases $moduleFolderTestCases {
            param( [string] $moduleFolderPath )

            $hasARM = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.json'))
            $hasBicep = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.bicep'))
            ($hasARM -or $hasBicep) | Should -Be $true
        }

        It '[<moduleFolderName>] Module should contain a [readme.md] file' -TestCases $moduleFolderTestCases {
            param( [string] $moduleFolderPath )
            (Test-Path (Join-Path -Path $moduleFolderPath 'readme.md')) | Should -Be $true
        }

        It '[<moduleFolderName>] Module should contain a [.parameters] folder' -TestCases $moduleFolderTestCases {
            param( [string] $moduleFolderPath )
            if ((Split-Path (Split-Path $moduleFolderPath -Parent) -Leaf) -like 'Microsoft.*') {
                (Test-Path (Join-Path -Path $moduleFolderPath '.parameters')) | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }

        It '[<moduleFolderName>] Module should contain a [version.json] file' -TestCases $moduleFolderTestCases {
            param( [string] $moduleFolderPath )
            (Test-Path (Join-Path -Path $moduleFolderPath 'version.json')) | Should -Be $true
        }
    }

    Context '.parameters folder' {

        $folderTestCases = [System.Collections.ArrayList]@()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            if (Test-Path (Join-Path $moduleFolderPath '.paramateres')) {
                $folderTestCases += @{
                    moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]
                    moduleFolderPath = $moduleFolderPath
                }
            }
        }

        It '[<moduleFolderName>] folder should contain one or more *parameters.json files' -TestCases $folderTestCases {
            param(
                $moduleFolderName,
                $moduleFolderPath
            )
            $parameterFolderPath = Join-Path $moduleFolderPath '.parameters'
            (Get-ChildItem $parameterFolderPath -Filter '*parameters.json' -Force).Count | Should -BeGreaterThan 0
        }

        $parameterFolderFilesTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            $parameterFolderPath = Join-Path $moduleFolderPath '.parameters'
            if (Test-Path $parameterFolderPath) {
                foreach ($parameterFile in (Get-ChildItem $parameterFolderPath -Filter '*parameters.json' -Force)) {
                    $parameterFolderFilesTestCases += @{
                        moduleFolderName  = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]
                        parameterFilePath = $parameterFile.FullName
                    }
                }
            }
        }

        It '[<moduleFolderName>] *parameters.json files in the .parameters folder should be valid json' -TestCases $parameterFolderFilesTestCases {
            param(
                $moduleFolderName,
                $parameterFilePath
            )
            (Get-Content $parameterFilePath) | ConvertFrom-Json
        }
    }
}

Describe 'Deployment template tests' -Tag Template {

    Context 'Deployment template tests' {

        $deploymentFolderTestCases = [System.Collections.ArrayList] @()
        $deploymentFolderTestCasesException = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {

            if (Test-Path (Join-Path $moduleFolderPath 'deploy.bicep')) {
                $templateContent = az bicep build --file (Join-Path $moduleFolderPath 'deploy.bicep') --stdout | ConvertFrom-Json -AsHashtable
            } elseif (Test-Path (Join-Path $moduleFolderPath 'deploy.json')) {
                $templateContent = Get-Content (Join-Path $moduleFolderPath 'deploy.json') -Raw | ConvertFrom-Json -AsHashtable
            } else {
                throw "No template file found in folder [$moduleFolderPath]"
            }

            # Parameter file test cases
            $parameterFileTestCases = @()
            $templateFile_Parameters = $templateContent.parameters
            $TemplateFile_AllParameterNames = $templateFile_Parameters.Keys | Sort-Object
            $TemplateFile_RequiredParametersNames = ($templateFile_Parameters.Keys | Where-Object { -not $templateFile_Parameters[$_].ContainsKey('defaultValue') }) | Sort-Object

            if (Test-Path (Join-Path $moduleFolderPath '.parameters')) {
                $ParameterFilePaths = (Get-ChildItem (Join-Path -Path $moduleFolderPath -ChildPath '.parameters' -AdditionalChildPath '*parameters.json') -Recurse -Force).FullName
                foreach ($ParameterFilePath in $ParameterFilePaths) {
                    $parameterFile_AllParameterNames = ((Get-Content $ParameterFilePath) | ConvertFrom-Json -AsHashtable).parameters.Keys | Sort-Object
                    $parameterFileTestCases += @{
                        parameterFile_Path                   = $ParameterFilePath
                        parameterFile_Name                   = Split-Path $ParameterFilePath -Leaf
                        parameterFile_AllParameterNames      = $parameterFile_AllParameterNames
                        templateFile_AllParameterNames       = $TemplateFile_AllParameterNames
                        templateFile_RequiredParametersNames = $TemplateFile_RequiredParametersNames
                        tokenSettings                        = $Settings.parameterFileTokens
                    }
                }
            }

            # Test file setup
            $deploymentFolderTestCases += @{
                moduleFolderName       = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]
                templateContent        = $templateContent
                parameterFileTestCases = $parameterFileTestCases
            }
        }
        foreach ($moduleFolderPath in $moduleFolderPathsFiltered) {
            $deploymentFolderTestCasesException += @{
                moduleFolderNameException = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]
                templateContent           = $templateContent
            }
        }

        It '[<moduleFolderName>] the template file should not be empty' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $templateContent | Should -Not -Be $null
        }

        It '[<moduleFolderName>] Template schema version should be the latest' -TestCases $deploymentFolderTestCases {
            # the actual value changes depending on the scope of the template (RG, subscription, MG, tenant) !!
            # https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax
            param(
                $moduleFolderName,
                $templateContent
            )

            $Schemaverion = $templateContent.'$schema'
            $SchemaArray = @()
            if ($Schemaverion -eq $RGdeployment) {
                $SchemaOutput = $true
            } elseif ($Schemaverion -eq $Subscriptiondeployment) {
                $SchemaOutput = $true
            } elseif ($Schemaverion -eq $MGdeployment) {
                $SchemaOutput = $true
            } elseif ($Schemaverion -eq $Tenantdeployment) {
                $SchemaOutput = $true
            } else {
                $SchemaOutput = $false
            }
            $SchemaArray += $SchemaOutput
            $SchemaArray | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] Template schema should use HTTPS reference' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $Schemaverion = $templateContent.'$schema'
            ($Schemaverion.Substring(0, 5) -eq 'https') | Should -Be $true
        }

        It '[<moduleFolderName>] All apiVersion properties should be set to a static, hard-coded value' -TestCases $deploymentFolderTestCases {
            #https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-best-practices
            param(
                $moduleFolderName,
                $templateContent
            )
            $ApiVersion = $templateContent.resources.apiVersion
            $ApiVersionArray = @()
            foreach ($API in $ApiVersion) {
                if ($API.Substring(0, 2) -eq '20') {
                    $ApiVersionOutput = $true
                } elseif ($API.substring(1, 10) -eq 'parameters') {
                    # An API version should not be referenced as a parameter
                    $ApiVersionOutput = $false
                } elseif ($API.substring(1, 10) -eq 'variables') {
                    # An API version should not be referenced as a variable
                    $ApiVersionOutput = $false
                } else {
                    $ApiVersionOutput = $false
                }
                $ApiVersionArray += $ApiVersionOutput
            }
            $ApiVersionArray | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] the template file should contain required elements: schema, contentVersion, resources' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $templateContent.Keys | Should -Contain '$schema'
            $templateContent.Keys | Should -Contain 'contentVersion'
            $templateContent.Keys | Should -Contain 'resources'
        }

        It '[<moduleFolderName>] If delete lock is implemented, the template should have a lock parameter with the default value of [NotSpecified]' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            if ($lock = $templateContent.parameters.lock) {
                $lock.Keys | Should -Contain 'defaultValue'
                $lock.defaultValue | Should -Be 'NotSpecified'
            }
        }

        It '[<moduleFolderName>] Parameter names should be camel-cased (no dashes or underscores and must start with lower-case letter)' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )

            if (-not $templateContent.parameters) {
                $true | Should -Be $true
                return
            }

            $CamelCasingFlag = @()
            $Parameter = $templateContent.parameters.Keys
            foreach ($Param in $Parameter) {
                if ($Param.substring(0, 1) -cnotmatch '[a-z]' -or $Param -match '-' -or $Param -match '_') {
                    $CamelCasingFlag += $false
                } else {
                    $CamelCasingFlag += $true
                }
            }
            $CamelCasingFlag | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] Variable names should be camel-cased (no dashes or underscores and must start with lower-case letter)' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )

            if (-not $templateContent.variables) {
                $true | Should -Be $true
                return
            }

            $CamelCasingFlag = @()
            $Variable = $templateContent.variables.Keys

            foreach ($Variab in $Variable) {
                if ($Variab.substring(0, 1) -cnotmatch '[a-z]' -or $Variab -match '-') {
                    $CamelCasingFlag += $false
                } else {
                    $CamelCasingFlag += $true
                }
            }
            $CamelCasingFlag | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] Output names should be camel-cased (no dashes or underscores and must start with lower-case letter)' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $CamelCasingFlag = @()
            $Outputs = $templateContent.outputs.Keys

            foreach ($Output in $Outputs) {
                if ($Output.substring(0, 1) -cnotmatch '[a-z]' -or $Output -match '-' -or $Output -match '_') {
                    $CamelCasingFlag += $false
                } else {
                    $CamelCasingFlag += $true
                }
            }
            $CamelCasingFlag | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] CUA ID deployment should be present in the template' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $enableDefaultTelemetryFlag = @()
            $Schemaverion = $templateContent.'$schema'
            if ((($Schemaverion.Split('/')[5]).Split('.')[0]) -eq (($RGdeployment.Split('/')[5]).Split('.')[0])) {
                if (($templateContent.resources.type -ccontains 'Microsoft.Resources/deployments' -and $templateContent.resources.condition -like "*[parameters('enableDefaultTelemetry')]*") -or ($templateContent.resources.resources.type -ccontains 'Microsoft.Resources/deployments' -and $templateContent.resources.resources.condition -like "*[parameters('enableDefaultTelemetry')]*")) {
                    $enableDefaultTelemetryFlag += $true
                } else {
                    $enableDefaultTelemetryFlag += $false
                }
            }
            $enableDefaultTelemetryFlag | Should -Not -Contain $false
        }

        It "[<moduleFolderName>] The Location should be defined as a parameter, with the default value of 'resourceGroup().Location' or global for ResourceGroup deployment scope" -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )
            $LocationFlag = $true
            $Schemaverion = $templateContent.'$schema'
            if ((($Schemaverion.Split('/')[5]).Split('.')[0]) -eq (($RGdeployment.Split('/')[5]).Split('.')[0])) {
                $Locationparamoutputvalue = $templateContent.parameters.location.defaultValue
                $Locationparamoutput = $templateContent.parameters.Keys
                if ($Locationparamoutput -contains 'Location') {
                    if ($Locationparamoutputvalue -eq '[resourceGroup().Location]' -or $Locationparamoutputvalue -eq 'global') {
                        $LocationFlag = $true
                    } else {

                        $LocationFlag = $false
                    }
                    $LocationFlag | Should -Contain $true
                }
            }
        }

        It "[<moduleFolderNameException>] All resources that have a Location property should refer to the Location parameter 'parameters('Location')'" -TestCases $deploymentFolderTestCasesException {
            param(
                $moduleFolderNameException,
                $templateContent
            )
            $LocationParamFlag = @()
            $Locmandoutput = $templateContent.resources
            foreach ($Locmand in $Locmandoutput) {
                if ($Locmand.Keys -contains 'Location' -and $Locmand.Location -eq "[parameters('Location')]") {
                    $LocationParamFlag += $true
                } elseif ($Locmand.Keys -notcontains 'Location') {
                    $LocationParamFlag += $true
                } elseif ($Locmand.Keys -notcontains 'resourceGroup') {
                    $LocationParamFlag += $true
                } else {
                    $LocationParamFlag += $false
                }
                foreach ($Locm in $Locmand.resources) {
                    if ($Locm.Keys -contains 'Location' -and $Locm.Location -eq "[parameters('Location')]") {
                        $LocationParamFlag += $true
                    } elseif ($Locm.Keys -notcontains 'Location') {
                        $LocationParamFlag += $true
                    } else {
                        $LocationParamFlag += $false
                    }
                }
            }
            $LocationParamFlag | Should -Not -Contain $false
        }

        It '[<moduleFolderName>] Standard outputs should be provided (e.g. resourceName, resourceId, resouceGroupName)' -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )

            $Stdoutput = $templateContent.outputs.Keys
            $i = 0
            $Schemaverion = $templateContent.'$schema'
            if ((($Schemaverion.Split('/')[5]).Split('.')[0]) -eq (($RGdeployment.Split('/')[5]).Split('.')[0])) {
                # Resource Group Level deployment
                foreach ($Stdo in $Stdoutput) {
                    if ($Stdo -like '*Name*' -or $Stdo -like '*ResourceId*' -or $Stdo -like '*ResourceGroup*') {
                        $true | Should -Be $true
                        $i = $i + 1
                    }
                }
                $i | Should -Not -BeLessThan 3
            } ElseIf ((($schemaverion.Split('/')[5]).Split('.')[0]) -eq (($Subscriptiondeployment.Split('/')[5]).Split('.')[0])) {
                # Subscription Level deployment
                $Stdoutput | Should -Not -BeNullOrEmpty
            }

        }

        It "[<moduleFolderName>] parameters' description shoud start with a one word category followed by a dot, a space and the actual description text." -TestCases $deploymentFolderTestCases {
            param(
                $moduleFolderName,
                $templateContent
            )

            if (-not $templateContent.parameters) {
                # Skip test
                $true | Should -Be $true
                return
            }

            $IncorrectParameters = @()
            $Paramdescoutput = $templateContent.parameters.Keys
            foreach ($Param in $Paramdescoutput) {
                $Data = ($templateContent.parameters.$Param.metadata).description
                if ($Data -notmatch '^[a-zA-Z]+\. .+') {
                    $IncorrectParameters += $Param
                }
            }
            $IncorrectParameters | Should -BeNullOrEmpty
        }

        # PARAMETER Tests
        It '[<moduleFolderName>] All parameters in parameters files exist in template file (deploy.json)' -TestCases $deploymentFolderTestCases {
            param (
                [hashtable[]] $parameterFileTestCases
            )

            foreach ($parameterFileTestCase in $parameterFileTestCases) {
                $parameterFile_AllParameterNames = $parameterFileTestCase.parameterFile_AllParameterNames
                $templateFile_AllParameterNames = $parameterFileTestCase.templateFile_AllParameterNames

                $nonExistentParameters = $parameterFile_AllParameterNames | Where-Object { $templateFile_AllParameterNames -notcontains $_ }
                $nonExistentParameters.Count | Should -Be 0 -Because ('no parameter in the parameter file should not exist in the template file. Found excess items: [{0}]' -f ($nonExistentParameters -join ', '))
            }
        }

        It '[<moduleFolderName>] All required parameters in template file (deploy.json) should exist in parameters files' -TestCases $deploymentFolderTestCases {
            param (
                [hashtable[]] $parameterFileTestCases
            )

            foreach ($parameterFileTestCase in $parameterFileTestCases) {
                $TemplateFile_RequiredParametersNames = $parameterFileTestCase.TemplateFile_RequiredParametersNames
                $parameterFile_AllParameterNames = $parameterFileTestCase.parameterFile_AllParameterNames

                $missingParameters = $templateFile_RequiredParametersNames | Where-Object { $parameterFile_AllParameterNames -notcontains $_ }
                $missingParameters.Count | Should -Be 0 -Because ('no required parameters in the template file should be missing in the parameter file. Found missing items: [{0}]' -f ($missingParameters -join ', '))
            }
        }

        It '[<moduleFolderName>] [Tokens] Parameter files should not contain the default Subscription ID guid' -TestCases $deploymentFolderTestCases {
            param (
                [hashtable[]] $ParameterFileTestCases
            )
            foreach ($ParameterFileTestCase in $ParameterFileTestCases) {
                $ParameterFileTokenName = -join ($ParameterFileTestCase.tokenSettings.tokenPrefix, 'subscriptionId', $ParameterFileTestCase.tokenSettings.tokenSuffix)
                $ParameterFileContent = Get-Content -Path $ParameterFileTestCase.parameterFile_Path
                $SubscriptionIdKeyCount = ($ParameterFileContent | Select-String -Pattern '"subscriptionId"', "'subscriptionId'", '/subscriptions/' -AllMatches).Matches.Count
                $SubscriptionIdValueCount = ($ParameterFileContent | Select-String -Pattern "$ParameterFileTokenName" -AllMatches).Matches.Count
                $SubscriptionIdKeyCount -eq $SubscriptionIdValueCount | Should -Be $true -Because ("Parameter file should not contain the Subscription ID guid, instead should reference a token value '$ParameterFileTokenName'")
            }
        }

        It '[<moduleFolderName>] [Tokens] Parameter files should not contain the default Tenant ID' -TestCases $deploymentFolderTestCases {
            param (
                [hashtable[]] $ParameterFileTestCases
            )
            foreach ($ParameterFileTestCase in $ParameterFileTestCases) {
                $ParameterFileTokenName = -join ($ParameterFileTestCase.tokenSettings.tokenPrefix, 'tenantId', $ParameterFileTestCase.tokenSettings.tokenSuffix)
                $ParameterFileContent = Get-Content -Path $ParameterFileTestCase.parameterFile_Path
                $TenantIdKeyCount = ($ParameterFileContent | Select-String -Pattern '"tenantId"', "'tenantId'" -AllMatches).Matches.Count
                $TenantIdValueCount = ($ParameterFileContent | Select-String -Pattern "$ParameterFileTokenName" -AllMatches).Matches.Count
                $TenantIdKeyCount -eq $TenantIdValueCount | Should -Be $true -Because ("Parameter file should not contain the Tenant ID guid, instead should reference a token value '$ParameterFileTokenName'")
            }
        }
    }
}

Describe "API version tests [All apiVersions in the template should be 'recent']" -Tag ApiCheck {

    $testCases = @()
    $ApiVersions = Get-AzResourceProvider -ListAvailable
    foreach ($moduleFolderPath in $moduleFolderPathsFiltered) {

        $moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/arm/')[1]

        if (Test-Path (Join-Path $moduleFolderPath 'deploy.bicep')) {
            $templateContent = az bicep build --file (Join-Path $moduleFolderPath 'deploy.bicep') --stdout | ConvertFrom-Json -AsHashtable
        } elseif (Test-Path (Join-Path $moduleFolderPath 'deploy.json')) {
            $templateContent = Get-Content (Join-Path $moduleFolderPath 'deploy.json') -Raw | ConvertFrom-Json -AsHashtable
        } else {
            throw "No template file found in folder [$moduleFolderPath]"
        }

        $nestedResources = Get-NestedResourceList -TemplateContent $templateContent | Where-Object {
            $_.type -notin @('Microsoft.Resources/deployments') -and $_
        } | Select-Object 'Type', 'ApiVersion' -Unique | Sort-Object Type

        foreach ($resource in $nestedResources) {

            switch ($resource.type) {
                { $PSItem -like '*diagnosticsettings*' } {
                    $testCases += @{
                        moduleName           = $moduleFolderName
                        resourceType         = 'diagnosticsettings'
                        ProviderNamespace    = 'Microsoft.insights'
                        TargetApi            = $resource.ApiVersion
                        AvailableApiVersions = $ApiVersions
                    }
                    break
                }
                { $PSItem -like '*locks' } {
                    $testCases += @{
                        moduleName           = $moduleFolderName
                        resourceType         = 'locks'
                        ProviderNamespace    = 'Microsoft.Authorization'
                        TargetApi            = $resource.ApiVersion
                        AvailableApiVersions = $ApiVersions
                    }
                    break
                }
                { $PSItem -like '*roleAssignments' } {
                    $testCases += @{
                        moduleName           = $moduleFolderName
                        resourceType         = 'roleassignments'
                        ProviderNamespace    = 'Microsoft.Authorization'
                        TargetApi            = $resource.ApiVersion
                        AvailableApiVersions = $ApiVersions
                    }
                    break
                }
                { $PSItem -like '*privateEndpoints' } {
                    $testCases += @{
                        moduleName           = $moduleFolderName
                        resourceType         = 'privateEndpoints'
                        ProviderNamespace    = 'Microsoft.Network'
                        TargetApi            = $resource.ApiVersion
                        AvailableApiVersions = $ApiVersions
                    }
                    break
                }
                Default {
                    $ProviderNamespace, $rest = $resource.Type.Split('/')
                    $testCases += @{
                        moduleName           = $moduleFolderName
                        resourceType         = $rest -join '/'
                        ProviderNamespace    = $ProviderNamespace
                        TargetApi            = $resource.ApiVersion
                        AvailableApiVersions = $ApiVersions
                    }
                    break
                }
            }
        }
    }

    It 'In [<moduleName>] used resource type [<resourceType>] should use one of the recent API version(s). Currently using [<TargetApi>]' -TestCases $TestCases {
        param(
            $moduleName,
            $resourceType,
            $TargetApi,
            $ProviderNamespace,
            $AvailableApiVersions
        )

        $namespaceResourceTypes = ($AvailableApiVersions | Where-Object { $_.ProviderNamespace -eq $ProviderNamespace }).ResourceTypes
        $resourceTypeApiVersions = ($namespaceResourceTypes | Where-Object { $_.ResourceTypeName -eq $resourceType }).ApiVersions

        if (-not $resourceTypeApiVersions) {
            Write-Warning ('[API Test] We are currently unable to determine the available API versions for resource type [{0}/{1}]' -f $ProviderNamespace, $resourceType)
            continue
        }

        # We allow the latest 5 including previews (in case somebody wants to use preview), or the latest 3 non-preview
        $approvedApiVersions = @()
        $approvedApiVersions += $resourceTypeApiVersions | Select-Object -First 5
        $approvedApiVersions += $resourceTypeApiVersions | Where-Object { $_ -notlike '*-preview' } | Select-Object -First 3
        ($approvedApiVersions | Select-Object -Unique) | Should -Contain $TargetApi
    }
}
