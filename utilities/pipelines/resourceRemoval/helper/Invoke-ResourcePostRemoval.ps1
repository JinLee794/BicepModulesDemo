﻿<#
.SYNOPSIS
Remove any artifacts that remain of the given resource

.DESCRIPTION
Remove any artifacts that remain of the given resource. For example, some resources such as key vaults usually go into a soft-delete state from which we want to purge them from.

.PARAMETER ResourceId
Mandatory. The resourceID of the resource to remove

.PARAMETER Type
Mandatory. The type of the resource to remove

.EXAMPLE
Invoke-ResourcePostRemoval -Type 'Microsoft.KeyVault/vaults' -ResourceId '/subscriptions/.../resourceGroups/validation-rg/providers/Microsoft.KeyVault/vaults/myVault'

Purge the resource 'myVault' of type 'Microsoft.KeyVault/vaults' with ID '/subscriptions/.../resourceGroups/validation-rg/providers/Microsoft.KeyVault/vaults/myVault' if no purge protection is enabled
#>
function Invoke-ResourcePostRemoval {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ResourceId,

        [Parameter(Mandatory = $true)]
        [string] $Type
    )

    switch ($type) {
        'Microsoft.KeyVault/vaults' {
            $resourceName = Split-Path $ResourceId -Leaf

            $matchingKeyVault = Get-AzKeyVault -InRemovedState | Where-Object { $_.resourceId -eq $ResourceId }
            if ($matchingKeyVault -and -not $matchingKeyVault.EnablePurgeProtection) {
                Write-Verbose ("Purging key vault [$resourceName]") -Verbose
                if ($PSCmdlet.ShouldProcess(('Key Vault with ID [{0}]' -f $matchingKeyVault.Id), 'Purge')) {
                    $null = Remove-AzKeyVault -ResourceId $matchingKeyVault.Id -InRemovedState -Force -Location $matchingKeyVault.Location
                }
            }
            break
        }
        'Microsoft.CognitiveServices/accounts' {
            $resourceGroupName = $resourceId.Split('/')[4]
            $resourceName = Split-Path $ResourceId -Leaf

            $matchingAccount = Get-AzCognitiveServicesAccount -InRemovedState | Where-Object { $_.AccountName -eq $resourceName }
            if ($matchingAccount) {
                if ($PSCmdlet.ShouldProcess(('Cognitive services account with ID [{0}]' -f $matchingAccount.Id), 'Purge')) {
                    $null = Remove-AzCognitiveServicesAccount -InRemovedState -Force -Location $matchingAccount.Location -ResourceGroupName $resourceGroupName -Name $matchingAccount.AccountName
                }
            }
            break
        }
        'Microsoft.ApiManagement/service' {
            $subscriptionId = $resourceId.Split('/')[2]
            $resourceName = Split-Path $ResourceId -Leaf

            # Fetch service in soft-delete
            $getPath = '/subscriptions/{0}/providers/Microsoft.ApiManagement/deletedservices?api-version=2021-08-01' -f $subscriptionId
            $getRequestInputObject = @{
                Method = 'GET'
                Path   = $getPath
            }
            $softDeletedService = ((Invoke-AzRestMethod @getRequestInputObject).Content | ConvertFrom-Json).value | Where-Object { $_.properties.serviceId -eq $resourceId }

            if ($softDeletedService) {
                # Purge service
                $purgePath = '/subscriptions/{0}/providers/Microsoft.ApiManagement/locations/{1}/deletedservices/{2}?api-version=2020-06-01-preview' -f $subscriptionId, $softDeletedService.location, $resourceName
                $purgeRequestInputObject = @{
                    Method = 'DELETE'
                    Path   = $purgePath
                }
                if ($PSCmdlet.ShouldProcess(('API management service with ID [{0}]' -f $softDeletedService.properties.serviceId), 'Purge')) {
                    $null = Invoke-AzRestMethod @purgeRequestInputObject
                }
            }
            break
        }
        'Microsoft.OperationalInsights/workspaces' {
            $subscriptionId = $resourceId.Split('/')[2]
            $resourceGroupName = $resourceId.Split('/')[4]
            $resourceName = Split-Path $ResourceId -Leaf
            # Fetch service in soft-delete state
            $getPath = '/subscriptions/{0}/providers/Microsoft.OperationalInsights/deletedWorkspaces?api-version=2020-03-01-preview' -f $subscriptionId
            $getRequestInputObject = @{
                Method = 'GET'
                Path   = $getPath
            }
            $softDeletedService = ((Invoke-AzRestMethod @getRequestInputObject).Content | ConvertFrom-Json).value | Where-Object { $_.id -eq $resourceId -and $_.name -eq $resourceName }
            if ($softDeletedService) {
                # Recover service
                $location = $softDeletedService.location
                if ($PSCmdlet.ShouldProcess(('Log analytics workspace [{0}]' -f $resourceId), 'Recover')) {
                    $recoveredWorkspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $resourceName -Location $location
                }
                # Purge service
                if ($PSCmdlet.ShouldProcess(('Log analytics workspace with ID [{0}]' -f $resourceId), 'Purge')) {
                    $recoveredWorkspace | Remove-AzOperationalInsightsWorkspace -ForceDelete -Force
                }
            }
            break
        }
        'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems' {
            # Remove protected VM
            # Required if e.g. a VM was listed in an RSV and only that VM is removed
            $vaultId = $resourceId.split('/backupFabrics/')[0]
            $resourceName = Split-Path $ResourceId -Leaf
            $softDeleteStatus = (Get-AzRecoveryServicesVaultProperty -VaultId $vaultId).SoftDeleteFeatureState
            if ($softDeleteStatus -ne 'Disabled') {
                if ($PSCmdlet.ShouldProcess(('Soft-delete on RSV [{0}]' -f $vaultId), 'Set')) {
                    $null = Set-AzRecoveryServicesVaultProperty -VaultId $vaultId -SoftDeleteFeatureState 'Disable'
                }
            }

            $backupItemInputObject = @{
                BackupManagementType = 'AzureVM'
                WorkloadType         = 'AzureVM'
                VaultId              = $vaultId
                Name                 = $resourceName
            }
            if ($backupItem = Get-AzRecoveryServicesBackupItem @backupItemInputObject -ErrorAction 'SilentlyContinue') {
                Write-Verbose ('Removing Backup item [{0}] from RSV [{1}]' -f $backupItem.Name, $vaultId) -Verbose

                if ($backupItem.DeleteState -eq 'ToBeDeleted') {
                    if ($PSCmdlet.ShouldProcess('Soft-deleted backup data removal', 'Undo')) {
                        $null = Undo-AzRecoveryServicesBackupItemDeletion -Item $backupItem -VaultId $vaultId -Force
                    }
                }

                if ($PSCmdlet.ShouldProcess(('Backup item [{0}] from RSV [{1}]' -f $backupItem.Name, $vaultId), 'Remove')) {
                    $null = Disable-AzRecoveryServicesBackupProtection -Item $backupItem -VaultId $vaultId -RemoveRecoveryPoints -Force
                }
            }

            # Undo a potential soft delete state change
            $null = Set-AzRecoveryServicesVaultProperty -VaultId $vaultId -SoftDeleteFeatureState $softDeleteStatus.TrimEnd('d')
            break
        }
        ### CODE LOCATION: Add custom post-removal operation here
    }
}
