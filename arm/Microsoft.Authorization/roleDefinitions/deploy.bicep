targetScope = 'subscription'

@sys.description('Required. Name of the custom RBAC role to be created.')
param roleName string

@sys.description('Optional. Description of the custom RBAC role to be created.')
param description string = ''

@sys.description('Optional. List of allowed actions.')
param actions array = []

@sys.description('Optional. List of denied actions.')
param notActions array = []

@sys.description('Optional. List of allowed data actions. This is not supported if the assignableScopes contains Management Group Scopes')
param dataActions array = []

@sys.description('Optional. List of denied data actions. This is not supported if the assignableScopes contains Management Group Scopes')
param notDataActions array = []

@sys.description('Optional. The subscription ID where the Role Definition and Target Scope will be applied to. Use for both Subscription level and Resource Group Level.')
param subscriptionId string = ''

@sys.description('Optional. The name of the Resource Group where the Role Definition and Target Scope will be applied to.')
param resourceGroupName string = ''

@sys.description('Optional. Location deployment metadata.')
param location string = deployment().location

@sys.description('Optional. Role definition assignable scopes. If not provided, will use the current scope provided.')
param assignableScopes array = []

@sys.description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-7386cd39-b109-4cc6-bb80-bf12413d0a99-${uniqueString(deployment().name, location)}'
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}
module roleDefinition_sub 'subscription/deploy.bicep' = if (!empty(subscriptionId) && empty(resourceGroupName)) {
  name: '${uniqueString(deployment().name, location)}-RoleDefinition-Sub-Module'
  scope: subscription(subscriptionId)
  params: {
    roleName: roleName
    description: !empty(description) ? description : ''
    actions: !empty(actions) ? actions : []
    notActions: !empty(notActions) ? notActions : []
    dataActions: !empty(dataActions) ? dataActions : []
    notDataActions: !empty(notDataActions) ? notDataActions : []
    assignableScopes: !empty(assignableScopes) ? assignableScopes : []
    subscriptionId: subscriptionId
    location: location
  }
}

module roleDefinition_rg 'resourceGroup/deploy.bicep' = if (!empty(resourceGroupName) && !empty(subscriptionId)) {
  name: '${uniqueString(deployment().name, location)}-RoleDefinition-RG-Module'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    roleName: roleName
    description: !empty(description) ? description : ''
    actions: !empty(actions) ? actions : []
    notActions: !empty(notActions) ? notActions : []
    dataActions: !empty(dataActions) ? dataActions : []
    notDataActions: !empty(notDataActions) ? notDataActions : []
    assignableScopes: !empty(assignableScopes) ? assignableScopes : []
    subscriptionId: subscriptionId
    resourceGroupName: resourceGroupName
  }
}

@sys.description('The GUID of the Role Definition')
output name string = !empty(subscriptionId) && empty(resourceGroupName) ? roleDefinition_sub.outputs.name : roleDefinition_rg.outputs.name

@sys.description('The resource ID of the Role Definition')
output resourceId string = !empty(subscriptionId) && empty(resourceGroupName) ? roleDefinition_sub.outputs.resourceId : roleDefinition_rg.outputs.resourceId

@sys.description('The scope this Role Definition applies to')
output roleDefinitionScope string = !empty(subscriptionId) && empty(resourceGroupName) ? roleDefinition_sub.outputs.scope : roleDefinition_rg.outputs.scope
