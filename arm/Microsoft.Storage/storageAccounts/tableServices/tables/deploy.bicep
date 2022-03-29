@maxLength(24)
@description('Required. Name of the Storage Account.')
param storageAccountName string

@description('Optional. The name of the table service')
param tableServicesName string = 'default'

@description('Required. Name of the table.')
param name string

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-7386cd39-b109-4cc6-bb80-bf12413d0a99-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName

  resource tableServices 'tableServices@2021-04-01' existing = {
    name: tableServicesName
  }
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-06-01' = {
  name: name
  parent: storageAccount::tableServices
}

@description('The name of the deployed file share service')
output name string = table.name

@description('The resource ID of the deployed file share service')
output resourceId string = table.id

@description('The resource group of the deployed file share service')
output resourceGroupName string = resourceGroup().name
