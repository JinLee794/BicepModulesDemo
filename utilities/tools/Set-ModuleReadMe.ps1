﻿#requires -version 6.0

#region Helper functions
<#
.SYNOPSIS
Get a list of all resources (provider + service) in the given template content

.DESCRIPTION
Get a list of all resources (provider + service) in the given template content. Crawls through any children & nested deployment templates.

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.EXAMPLE
Get-NestedResourceList -TemplateFileContent @{ resource = @{}; ... }

Returns a list of all resources in the given template object
#>
function Get-NestedResourceList {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Path')]
        [hashtable] $TemplateFileContent
    )

    $res = @()
    $currLevelResources = @()
    if ($TemplateFileContent.resources) {
        $currLevelResources += $TemplateFileContent.resources
    }
    foreach ($resource in $currLevelResources) {
        $res += $resource

        if ($resource.type -eq 'Microsoft.Resources/deployments') {
            $res += Get-NestedResourceList -TemplateFileContent $resource.properties.template
        } else {
            $res += Get-NestedResourceList -TemplateFileContent $resource
        }
    }
    return $res
}

<#
.SYNOPSIS
Update the 'Resource Types' section of the given readme file

.DESCRIPTION
Update the 'Resource Types' section of the given readme file
The section is added at the end if it does not exist

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.PARAMETER ReadMeFileContent
Mandatory. The readme file content array to update

.PARAMETER SectionStartIdentifier
Optional. The identifier of the 'outputs' section. Defaults to '## Resource Types'

.PARAMETER ResourceTypesToExclude
Optional. The resource types to exclude from the list. By default excludes 'Microsoft.Resources/deployments'

.EXAMPLE
Set-ResourceTypesSection -TemplateFileContent @{ resource = @{}; ... } -ReadMeFileContent @('# Title', '', '## Section 1', ...)

Update the given readme file's 'Resource Types' section based on the given template file content
#>
function Set-ResourceTypesSection {

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ResourceTypesToExclude', Justification = 'Variable used inside Where-Object block.')]
    param (
        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Resource Types',

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceTypesToExclude = @('Microsoft.Resources/deployments')
    )

    # Process content
    $SectionContent = [System.Collections.ArrayList]@(
        '| Resource Type | API Version |',
        '| :-- | :-- |'
    )

    $RelevantResourceTypes = Get-NestedResourceList $TemplateFileContent | Where-Object {
        $_.type -notin $ResourceTypesToExclude -and $_
    } | Select-Object 'Type', 'ApiVersion' -Unique | Sort-Object Type -Culture en-US

    foreach ($resourceType in $RelevantResourceTypes) {
        $SectionContent += ('| `{0}` | {1} |' -f $resourceType.type, $resourceType.apiVersion)
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new resource type content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $SectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'table'
    }
    return $updatedFileContent
}

<#
.SYNOPSIS
Update the 'parameters' section of the given readme file

.DESCRIPTION
Update the 'parameters' section of the given readme file
The section is added at the end if it does not exist

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.PARAMETER ReadMeFileContent
Mandatory. The readme file content array to update

.PARAMETER currentFolderPath
Mandatory. The current folder path

.PARAMETER SectionStartIdentifier
Optional. The identifier of the 'outputs' section. Defaults to '## Parameters'

.EXAMPLE
Set-ParametersSection -TemplateFileContent @{ resource = @{}; ... } -ReadMeFileContent @('# Title', '', '## Section 1', ...)

Update the given readme file's 'Parameters' section based on the given template file content
#>
function Set-ParametersSection {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory)]
        [string] $currentFolderPath,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Parameters',

        [Parameter(Mandatory = $false)]
        [string[]] $ColumnsInOrder = @('Required', 'Conditional', 'Optional', 'Generated')
    )

    # Get all descriptions
    $descriptions = $TemplateFileContent.parameters.Values.metadata.description

    # Get the module parameter categories
    $paramCategories = $descriptions | ForEach-Object { $_.Split('.')[0] } | Select-Object -Unique

    # Sort categories
    $sortedParamCategories = $ColumnsInOrder | Where-Object { $paramCategories -contains $_ }
    # Add all others that exist but are not specified in the columnsInOrder parameter
    $sortedParamCategories += $paramCategories | Where-Object { $ColumnsInOrder -notcontains $_ }

    # Collect file information
    $currentLevelFolders = Get-ChildItem -Path $currentFolderPath -Directory -Depth 0
    $folderNames = ($null -ne $currentLevelFolders) ? ($currentLevelFolders.FullName | ForEach-Object { Split-Path $_ -Leaf }) : @()

    # Add name as property for later reference
    $TemplateFileContent.parameters.Keys | ForEach-Object { $TemplateFileContent.parameters[$_]['name'] = $_ }

    $newSectionContent = [System.Collections.ArrayList]@()
    # Create parameter blocks
    foreach ($category in $sortedParamCategories) {

        # 1. Prepare
        # Filter to relevant items
        [array] $categoryParameters = $TemplateFileContent.parameters.Values | Where-Object { $_.metadata.description -like "$category. *" } | Sort-Object -Property 'Name' -Culture 'en-US'

        # Check properties for later reference
        $hasDefaults = $categoryParameters.defaultValue.count -gt 0
        $hasAllowed = $categoryParameters.allowedValues.count -gt 0

        # 2. Create header including optional columns
        $newSectionContent += @(
            ('**{0} parameters**' -f $category),
            ('| Parameter Name | Type | {0}{1}Description |' -f ($hasDefaults ? 'Default Value | ' : ''), ($hasAllowed ? 'Allowed Values | ' : '')),
            ('| :-- | :-- | {0}{1}:-- |' -f ($hasDefaults ? ':-- | ' : ''), ($hasAllowed ? ':-- | ' : ''))
        )

        # 3. Add individual parameters
        foreach ($parameter in $categoryParameters) {

            # Check for local readme references
            if ($folderNames -and $parameter.name -in $folderNames -and $parameter.type -in @('object', 'array')) {
                if ($folderNames -contains $parameter.name) {
                    $type = '_[{0}]({0}/readme.md)_ {1}' -f $parameter.name, $parameter.type
                }
            } elseif ($folderNames -and $parameter.name -like '*Obj' -and $parameter.name.TrimEnd('Obj') -in $folderNames -and $parameter.type -in @('object', 'array')) {
                if ($folderNames -contains $parameter.name.TrimEnd('Obj')) {
                    $type = '_[{0}]({0}/readme.md)_ {1}' -f $parameter.name.TrimEnd('Obj'), $parameter.type
                }
            } else {
                $type = $parameter.type
            }

            $defaultValue = ($parameter.defaultValue -is [array]) ? ('[{0}]' -f ($parameter.defaultValue -join ', ')) : (($parameter.defaultValue -is [hashtable]) ? '{object}' : $parameter.defaultValue)
            $allowed = ($parameter.allowedValues -is [array]) ? ('[{0}]' -f ($parameter.allowedValues -join ', ')) : (($parameter.allowedValues -is [hashtable]) ? '{object}' : $parameter.allowedValues)
            $description = $parameter.metadata.description

            # Update parameter table content based on parameter category
            ## Remove category from parameter description
            $description = $description.substring("$category. ".Length)
            $defaultValueColumnValue = ($hasDefaults ? (-not [String]::IsNullOrEmpty($defaultValue) ? "``$defaultValue`` | " : ' | ') : '')
            $allowedColumnValue = ($hasAllowed ? (-not [String]::IsNullOrEmpty($allowed) ? "``$allowed`` | " : ' | ') : '')
            $newSectionContent += ('| `{0}` | {1} | {2}{3}{4} |' -f $parameter.name, $type, $defaultValueColumnValue, $allowedColumnValue, $description)
        }
        $newSectionContent += ''
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new parameters content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $newSectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'none'
    }

    # Build sub-section 'ParameterUsage'
    if (Test-Path (Join-Path $PSScriptRoot 'moduleReadMeSource')) {
        if ($resourceUsageSourceFiles = Get-ChildItem (Join-Path $PSScriptRoot 'moduleReadMeSource') -Recurse -Filter 'resourceUsage-*') {
            foreach ($sourceFile in $resourceUsageSourceFiles.FullName) {
                $parameterName = (Split-Path $sourceFile -LeafBase).Replace('resourceUsage-', '')
                if ($templateFileContent.parameters.Keys -contains $parameterName) {
                    $subSectionStartIdentifier = '### Parameter Usage: `{0}`' -f $ParameterName

                    # Build result
                    $updateParameterUsageInputObject = @{
                        OldContent             = $updatedFileContent
                        NewContent             = (Get-Content $sourceFile -Raw).Trim()
                        SectionStartIdentifier = $subSectionStartIdentifier
                        ParentStartIdentifier  = $SectionStartIdentifier
                        ContentType            = 'none'
                    }
                    if ($PSCmdlet.ShouldProcess(('Original file with new parameter usage [{0}] content' -f $parameterName), 'Merge')) {
                        $updatedFileContent = Merge-FileWithNewContent @updateParameterUsageInputObject
                    }
                }
            }
        }
    }

    return $updatedFileContent
}

<#
.SYNOPSIS
Update the 'outputs' section of the given readme file

.DESCRIPTION
Update the 'outputs' section of the given readme file
The section is added at the end if it does not exist

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.PARAMETER ReadMeFileContent
Mandatory. The readme file content array to update

.PARAMETER SectionStartIdentifier
Optional. The identifier of the 'outputs' section. Defaults to '## Outputs'

.EXAMPLE
Set-OutputsSection -TemplateFileContent @{ resource = @{}; ... } -ReadMeFileContent @('# Title', '', '## Section 1', ...)

Update the given readme file's 'Outputs' section based on the given template file content
#>
function Set-OutputsSection {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Outputs'
    )

    # Process content
    if ($TemplateFileContent.outputs.Values.metadata) {
        # Template has output descriptions
        $SectionContent = [System.Collections.ArrayList]@(
            '| Output Name | Type | Description |',
            '| :-- | :-- | :-- |'
        )
        foreach ($outputName in ($templateFileContent.outputs.Keys | Sort-Object -Culture en-US)) {
            $output = $TemplateFileContent.outputs[$outputName]
            $SectionContent += ("| ``{0}`` | {1} | {2} |" -f $outputName, $output.type, $output.metadata.description)
        }
    } else {
        $SectionContent = [System.Collections.ArrayList]@(
            '| Output Name | Type |',
            '| :-- | :-- |'
        )
        foreach ($outputName in ($templateFileContent.outputs.Keys | Sort-Object -Culture en-US)) {
            $output = $TemplateFileContent.outputs[$outputName]
            $SectionContent += ("| ``{0}`` | {1} |" -f $outputName, $output.type)
        }
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new output content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $SectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'table'
    }
    return $updatedFileContent
}

<#
.SYNOPSIS
Update the 'Template references' section of the given readme file

.DESCRIPTION
Update the 'Template references' section of the given readme file
The section is added at the end if it does not exist

.PARAMETER TemplateFileContent
Mandatory. The template file content object to crawl data from

.PARAMETER ReadMeFileContent
Mandatory. The readme file content array to update

.PARAMETER SectionStartIdentifier
Optional. The identifier of the 'outputs' section. Defaults to '## Template references'

.PARAMETER ResourceTypesToExclude
Optional. The resource types to exclude from the list. By default excludes 'Microsoft.Resources/deployments'

.EXAMPLE
Set-ResourceTypesSection -TemplateFileContent @{ resource = @{}; ... } -ReadMeFileContent @('# Title', '', '## Section 1', ...)

Update the given readme file's 'Template references' section based on the given template file content
#>
function Set-TemplateReferencesSection {

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ResourceTypesToExclude', Justification = 'Variable used inside Where-Object block.')]
    param (
        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Template references',

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceTypesToExclude = @('Microsoft.Resources/deployments')
    )

    # Process content
    $SectionContent = [System.Collections.ArrayList]@()

    $RelevantResourceTypes = Get-NestedResourceList $TemplateFileContent | Where-Object {
        $_.type -notin $ResourceTypesToExclude -and $_ -and $_.type -notlike '*/providers/*'
    } | Select-Object 'Type', 'ApiVersion' -Unique | Sort-Object Type -Culture en-US

    $TextInfo = (Get-Culture).TextInfo
    foreach ($RelevantResourceType in $RelevantResourceTypes) {
        $ProviderNamespace, $ResourceType = $RelevantResourceType.Type -split '/', 2
        $ResourceReferenceTitle = $TextInfo.ToTitleCase($ResourceType)
        # Validate if Reference URL Is working
        $TemplatesBaseUrl = 'https://docs.microsoft.com/en-us/azure/templates'
        try {
            $ResourceReferenceUrl = '{0}/{1}/{2}/{3}' -f $TemplatesBaseUrl, $ProviderNamespace, $RelevantResourceType.ApiVersion, $ResourceType
            $null = Invoke-WebRequest -Uri $ResourceReferenceUrl
        } catch {
            # Validate if Reference URL is working using the latest documented API version (with no API version in the URL)
            try {
                $ResourceReferenceUrl = '{0}/{1}/{2}' -f $TemplatesBaseUrl, $ProviderNamespace, $ResourceType
                $null = Invoke-WebRequest -Uri $ResourceReferenceUrl
            } catch {
                # Check if the resource is a child resource
                if ($ResourceType.Split('/').length -gt 1) {
                    $ResourceReferenceUrl = '{0}/{1}/{2}' -f $TemplatesBaseUrl, $ProviderNamespace, $ResourceType.Split('/')[0]
                    $ResourceReferenceTitle = "'$ResourceType' Parent Documentation"
                } else {
                    # Use the default Templates URL (Last resort)
                    $ResourceReferenceUrl = '{0}' -f $TemplatesBaseUrl
                    $ResourceReferenceTitle = 'Define resources with Bicep and ARM templates'
                }
            }
        }
        $SectionContent += ('- [{0}]({1})' -f $ResourceReferenceTitle, $ResourceReferenceUrl)
    }
    $SectionContent = $SectionContent | Sort-Object -Unique
    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new template references content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $SectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'list'
    }
    return $updatedFileContent
}

<#
.SYNOPSIS
Generate a table of content section for the given readme file

.DESCRIPTION
Generate a table of content section for the given readme file

.PARAMETER ReadMeFileContent
Mandatory. The readme file content array to update

.PARAMETER SectionStartIdentifier
Optional. The identifier of the 'navigation' section. Defaults to '## Navigation'

.EXAMPLE
Set-TableOfContent -ReadMeFileContent @('# Title', '', '## Section 1', ...)


Update the given readme's '## Navigation' section to reflect the latest file structure
#>
function Set-TableOfContent {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Navigation'
    )

    $newSectionContent = [System.Collections.ArrayList]@()

    $contentPointer = 1
    while ($ReadMeFileContent[$contentPointer] -notlike '#*') {
        $contentPointer++
    }

    $headers = $ReadMeFileContent.Split('\n') | Where-Object { $_ -like '## *' }

    if ($headers -notcontains $SectionStartIdentifier) {
        $beforeContent = $ReadMeFileContent[0 .. ($contentPointer - 1)]
        $afterContent = $ReadMeFileContent[$contentPointer .. ($ReadMeFileContent.Count - 1)]

        $ReadMeFileContent = $beforeContent + @($SectionStartIdentifier, '') + $afterContent
    }

    $headers | Where-Object { $_ -ne $SectionStartIdentifier } | ForEach-Object {
        $newSectionContent += '- [{0}](#{1})' -f $_.Replace('#', '').Trim(), $_.Replace('#', '').Trim().Replace(' ', '-').Replace('.', '')
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new parameters content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $newSectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'none'
    }

    return $updatedFileContent
}
#endregion

<#
.SYNOPSIS
Update/add the readme that matches the given template file

.DESCRIPTION
Update/add the readme that matches the given template file
Supports both ARM & bicep templates.

.PARAMETER TemplateFilePath
Mandatory. The path to the template to update

.PARAMETER ReadMeFilePath
Optional. The path to the readme to update. If not provided assumes a 'readme.md' file in the same folder as the template

.PARAMETER SectionsToRefresh
Optional. The sections to update. By default it refreshes all that are supported.
Currently supports: 'Resource Types', 'Parameters', 'Outputs', 'Template references'

.EXAMPLE
Set-ModuleReadMe -TemplateFilePath 'C:\deploy.bicep'

Update the readme in path 'C:\readme.md' based on the bicep template in path 'C:\deploy.bicep'

.EXAMPLE
Set-ModuleReadMe -TemplateFilePath 'C:/Microsoft.Network/loadBalancers/deploy.bicep' -SectionsToRefresh @('Parameters', 'Outputs')

Generate the Module ReadMe only for specific sections. Updates only the sections `Parameters` & `Outputs`. Other sections remain untouched.

.EXAMPLE
Set-ModuleReadMe -TemplateFilePath 'C:/Microsoft.Network/loadBalancers/deploy.bicep' -ReadMeFilePath 'C:/differentFolder'

Generate the Module ReadMe files into a specific folder path

.EXAMPLE
$templatePaths = (Get-ChildItem 'C:/Microsoft.Network' -Filter 'deploy.bicep' -Recurse).FullName
$templatePaths | ForEach-Object { Set-ModuleReadMe -TemplateFilePath $_ }

Generate the Module ReadMe for any template in a folder path

.NOTES
The script autopopulates the Parameter Usage section of the ReadMe with the matching content in path './moduleReadMeSource'.
The content is added in case the given template has a parameter that matches the suffix of one of the files in that path.
To account for more parameter, just add another markdown file with the naming pattern 'resourceUsage-<parameterName>'
#>
function Set-ModuleReadMe {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string] $TemplateFilePath,

        [Parameter(Mandatory = $false)]
        [string] $ReadMeFilePath = (Join-Path (Split-Path $TemplateFilePath -Parent) 'readme.md'),

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'Resource Types',
            'Parameters',
            'Outputs',
            'Template references'
        )]
        [string[]] $SectionsToRefresh = @(
            'Resource Types',
            'Parameters',
            'Outputs',
            'Template references',
            'Navigation'
        )
    )

    # Load external functions
    . (Join-Path $PSScriptRoot 'helper/Merge-FileWithNewContent.ps1')

    # Check template
    $null = Test-Path $TemplateFilePath -ErrorAction Stop

    if ((Split-Path -Path $TemplateFilePath -Extension) -eq '.bicep') {
        $templateFileContent = az bicep build --file $TemplateFilePath --stdout | ConvertFrom-Json -AsHashtable
    } else {
        $templateFileContent = ConvertFrom-Json (Get-Content $TemplateFilePath -Encoding 'utf8' -Raw) -ErrorAction Stop -AsHashtable
    }

    $fullResourcePath = (Split-Path $TemplateFilePath -Parent).Replace('\', '/').split('/arm/')[1]

    # Check readme
    if (-not (Test-Path $ReadMeFilePath) -or ([String]::IsNullOrEmpty((Get-Content $ReadMeFilePath -Raw)))) {
        # Create new readme file

        # Build resource name
        $serviceIdentifiers = $fullResourcePath.Replace('Microsoft.', '').Replace('/.', '/').Split('/')
        $serviceIdentifiers = $serviceIdentifiers | ForEach-Object { $_.substring(0, 1).toupper() + $_.substring(1) }
        $serviceIdentifiers = $serviceIdentifiers | ForEach-Object { $_ -creplace '(?<=\w)([A-Z])', '$1' }
        $assumedResourceName = $serviceIdentifiers -join ' '

        $initialContent = @(
            "# $assumedResourceName ``[$fullResourcePath]``",
            '',
            "This module deploys $assumedResourceName."
            '// TODO: Replace Resource and fill in description',
            ''
            '## Resource Types',
            '',
            '## Parameters',
            '',
            '### Parameter Usage: `<ParameterPlaceholder>`'
            ''
            '// TODO: Fill in Parameter usage'
            '',
            '## Outputs',
            '',
            '## Template references'
        )
        # New-Item $path $ReadMeFilePath -ItemType 'File' -Force -Value $initialContent
        $readMeFileContent = $initialContent
    } else {
        $readMeFileContent = Get-Content -Path $ReadMeFilePath -Encoding 'utf8'
    }

    # Update title
    if ($TemplateFilePath.Replace('\', '/') -like '*/arm/*') {

        if ($readMeFileContent[0] -notlike "*``[$fullResourcePath]``") {
            # Cut outdated
            $readMeFileContent[0] = $readMeFileContent[0].Split('`[')[0]

            # Add latest
            $readMeFileContent[0] = '{0} `[{1}]`' -f $readMeFileContent[0], $fullResourcePath
        }
        # Remove excess whitespace
        $readMeFileContent[0] = $readMeFileContent[0] -replace '\s+', ' '
    }

    if ($SectionsToRefresh -contains 'Resource Types') {
        # Handle [Resource Types] section
        # ===============================
        $inputObject = @{
            ReadMeFileContent   = $readMeFileContent
            TemplateFileContent = $templateFileContent
        }
        $readMeFileContent = Set-ResourceTypesSection @inputObject
    }

    if ($SectionsToRefresh -contains 'Parameters') {
        # Handle [Parameters] section
        # ===========================
        $inputObject = @{
            ReadMeFileContent   = $readMeFileContent
            TemplateFileContent = $templateFileContent
            currentFolderPath   = (Split-Path $TemplateFilePath -Parent)
        }
        $readMeFileContent = Set-ParametersSection @inputObject
    }

    if ($SectionsToRefresh -contains 'Outputs') {
        # Handle [Outputs] section
        # ========================
        $inputObject = @{
            ReadMeFileContent   = $readMeFileContent
            TemplateFileContent = $templateFileContent
        }
        $readMeFileContent = Set-OutputsSection @inputObject
    }

    if ($SectionsToRefresh -contains 'Template references') {
        # Handle [TemplateReferences] section
        # ===================================
        $inputObject = @{
            ReadMeFileContent   = $readMeFileContent
            TemplateFileContent = $templateFileContent
        }
        $readMeFileContent = Set-TemplateReferencesSection @inputObject
    }

    if ($SectionsToRefresh -contains 'Navigation') {
        # Handle [Navigation] section
        # ===================================
        $inputObject = @{
            ReadMeFileContent = $readMeFileContent
        }
        $readMeFileContent = Set-TableOfContent @inputObject
    }

    Write-Verbose 'New content:'
    Write-Verbose '============'
    Write-Verbose ($readMeFileContent | Out-String)

    if ($PSCmdlet.ShouldProcess("File in path [$ReadMeFilePath]", 'Overwrite')) {
        Set-Content -Path $ReadMeFilePath -Value $readMeFileContent -Force -Encoding 'utf8'
        Write-Verbose "File [$ReadMeFilePath] updated" -Verbose
    }
}
