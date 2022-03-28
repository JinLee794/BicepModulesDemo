targetScope = 'resourceGroup'

@sys.description('Required. You can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'')
param roleDefinitionIdOrName string

@sys.description('Required. The Principal or Object ID of the Security Principal (User, Group, Service Principal, Managed Identity)')
param principalId string

@sys.description('Optional. Name of the Resource Group to assign the RBAC role to. If not provided, will use the current scope for deployment.')
param resourceGroupName string = resourceGroup().name

@sys.description('Optional. Subscription ID of the subscription to assign the RBAC role to. If not provided, will use the current scope for deployment.')
param subscriptionId string = subscription().subscriptionId

@sys.description('Optional. Description of role assignment')
param description string = ''

@sys.description('Optional. ID of the delegated managed identity resource')
param delegatedManagedIdentityResourceId string = ''

@sys.description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to')
param condition string = ''

@sys.description('Optional. Version of the condition. Currently accepted value is "2.0"')
@allowed([
  '2.0'
])
param conditionVersion string = '2.0'

@sys.description('Optional. The principal type of the assigned principal ID.')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
  'Device'
])
param principalType string

@sys.description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

var builtInRoleNames_var = {
  'AcrPush': '/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec'
  'API Management Service Contributor': '/providers/Microsoft.Authorization/roleDefinitions/312a565d-c81f-4fd8-895a-4e21e48d571c'
  'AcrPull': '/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  'AcrImageSigner': '/providers/Microsoft.Authorization/roleDefinitions/6cef56e8-d556-48e5-a04f-b8e64114680f'
  'AcrDelete': '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'
  'AcrQuarantineReader': '/providers/Microsoft.Authorization/roleDefinitions/cdda3590-29a3-44f6-95f2-9f980659eb04'
  'AcrQuarantineWriter': '/providers/Microsoft.Authorization/roleDefinitions/c8d4ff99-41c3-41a8-9f60-21dfdad59608'
  'API Management Service Operator Role': '/providers/Microsoft.Authorization/roleDefinitions/e022efe7-f5ba-4159-bbe4-b44f577e9b61'
  'API Management Service Reader Role': '/providers/Microsoft.Authorization/roleDefinitions/71522526-b88f-4d52-b57f-d31fc3546d0d'
  'Application Insights Component Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ae349356-3a1b-4a5e-921d-050484c6347e'
  'Application Insights Snapshot Debugger': '/providers/Microsoft.Authorization/roleDefinitions/08954f03-6346-4c2e-81c0-ec3a5cfae23b'
  'Attestation Reader': '/providers/Microsoft.Authorization/roleDefinitions/fd1bd22b-8476-40bc-a0bc-69b95687b9f3'
  'Automation Job Operator': '/providers/Microsoft.Authorization/roleDefinitions/4fe576fe-1146-4730-92eb-48519fa6bf9f'
  'Automation Runbook Operator': '/providers/Microsoft.Authorization/roleDefinitions/5fb5aef8-1081-4b8e-bb16-9d5d0385bab5'
  'Automation Operator': '/providers/Microsoft.Authorization/roleDefinitions/d3881f73-407a-4167-8283-e981cbba0404'
  'Avere Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4f8fab4f-1852-4a58-a46a-8eaf358af14a'
  'Avere Operator': '/providers/Microsoft.Authorization/roleDefinitions/c025889f-8102-4ebf-b32c-fc0c6f0c6bd9'
  'Azure Kubernetes Service Cluster Admin Role': '/providers/Microsoft.Authorization/roleDefinitions/0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
  'Azure Kubernetes Service Cluster User Role': '/providers/Microsoft.Authorization/roleDefinitions/4abbcc35-e782-43d8-92c5-2d3f1bd2253f'
  'Azure Maps Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/423170ca-a8f6-4b0f-8487-9e4eb8f49bfa'
  'Azure Stack Registration Owner': '/providers/Microsoft.Authorization/roleDefinitions/6f12a6df-dd06-4f3e-bcb1-ce8be600526a'
  'Backup Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5e467623-bb1f-42f4-a55d-6e525e11384b'
  'Billing Reader': '/providers/Microsoft.Authorization/roleDefinitions/fa23ad8b-c56e-40d8-ac0c-ce449e1d2c64'
  'Backup Operator': '/providers/Microsoft.Authorization/roleDefinitions/00c29273-979b-4161-815c-10b084fb9324'
  'Backup Reader': '/providers/Microsoft.Authorization/roleDefinitions/a795c7a0-d4a2-40c1-ae25-d81f01202912'
  'BizTalk Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5e3c6656-6cfa-4708-81fe-0de47ac73342'
  'CDN Endpoint Contributor': '/providers/Microsoft.Authorization/roleDefinitions/426e0c7f-0c7e-4658-b36f-ff54d6c29b45'
  'CDN Endpoint Reader': '/providers/Microsoft.Authorization/roleDefinitions/871e35f6-b5c1-49cc-a043-bde969a0f2cd'
  'CDN Profile Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ec156ff8-a8d1-4d15-830c-5b80698ca432'
  'CDN Profile Reader': '/providers/Microsoft.Authorization/roleDefinitions/8f96442b-4075-438f-813d-ad51ab4019af'
  'Classic Network Contributor': '/providers/Microsoft.Authorization/roleDefinitions/b34d265f-36f7-4a0d-a4d4-e158ca92e90f'
  'Classic Storage Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/86e8f5dc-a6e9-4c67-9d15-de283e8eac25'
  'Classic Storage Account Key Operator Service Role': '/providers/Microsoft.Authorization/roleDefinitions/985d6b00-f706-48f5-a6fe-d0ca12fb668d'
  'ClearDB MySQL DB Contributor': '/providers/Microsoft.Authorization/roleDefinitions/9106cda0-8a86-4e81-b686-29a22c54effe'
  'Classic Virtual Machine Contributor': '/providers/Microsoft.Authorization/roleDefinitions/d73bb868-a0df-4d4d-bd69-98a00b01fccb'
  'Cognitive Services User': '/providers/Microsoft.Authorization/roleDefinitions/a97b65f3-24c7-4388-baec-2e87135dc908'
  'Cognitive Services Contributor': '/providers/Microsoft.Authorization/roleDefinitions/25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
  'CosmosBackupOperator': '/providers/Microsoft.Authorization/roleDefinitions/db7b14f2-5adf-42da-9f96-f2ee17bab5cb'
  'Contributor': '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  'Cosmos DB Account Reader Role': '/providers/Microsoft.Authorization/roleDefinitions/fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
  'Cost Management Contributor': '/providers/Microsoft.Authorization/roleDefinitions/434105ed-43f6-45c7-a02f-909b2ba83430'
  'Cost Management Reader': '/providers/Microsoft.Authorization/roleDefinitions/72fafb9e-0641-4937-9268-a91bfd8191a3'
  'Data Box Contributor': '/providers/Microsoft.Authorization/roleDefinitions/add466c9-e687-43fc-8d98-dfcf8d720be5'
  'Data Box Reader': '/providers/Microsoft.Authorization/roleDefinitions/028f4ed7-e2a9-465e-a8f4-9c0ffdfdc027'
  'Data Factory Contributor': '/providers/Microsoft.Authorization/roleDefinitions/673868aa-7521-48a0-acc6-0f60742d39f5'
  'Data Purger': '/providers/Microsoft.Authorization/roleDefinitions/150f5e0c-0603-4f03-8c7f-cf70034c4e90'
  'Data Lake Analytics Developer': '/providers/Microsoft.Authorization/roleDefinitions/47b7735b-770e-4598-a7da-8b91488b4c88'
  'DevTest Labs User': '/providers/Microsoft.Authorization/roleDefinitions/76283e04-6283-4c54-8f91-bcf1374a3c64'
  'DocumentDB Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5bd9cd88-fe45-4216-938b-f97437e15450'
  'DNS Zone Contributor': '/providers/Microsoft.Authorization/roleDefinitions/befefa01-2a29-4197-83a8-272ff33ce314'
  'EventGrid EventSubscription Contributor': '/providers/Microsoft.Authorization/roleDefinitions/428e0ff0-5e57-4d9c-a221-2c70d0e0a443'
  'EventGrid EventSubscription Reader': '/providers/Microsoft.Authorization/roleDefinitions/2414bbcf-6497-4faf-8c65-045460748405'
  'Graph Owner': '/providers/Microsoft.Authorization/roleDefinitions/b60367af-1334-4454-b71e-769d9a4f83d9'
  'HDInsight Domain Services Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8d8d5a11-05d3-4bda-a417-a08778121c7c'
  'Intelligent Systems Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/03a6d094-3444-4b3d-88af-7477090a9e5e'
  'Key Vault Contributor': '/providers/Microsoft.Authorization/roleDefinitions/f25e0fa2-a7c8-4377-a976-54943a77a395'
  'Knowledge Consumer': '/providers/Microsoft.Authorization/roleDefinitions/ee361c5d-f7b5-4119-b4b6-892157c8f64c'
  'Lab Creator': '/providers/Microsoft.Authorization/roleDefinitions/b97fb8bc-a8b2-4522-a38b-dd33c7e65ead'
  'Log Analytics Reader': '/providers/Microsoft.Authorization/roleDefinitions/73c42c96-874c-492b-b04d-ab87d138a893'
  'Log Analytics Contributor': '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  'Logic App Operator': '/providers/Microsoft.Authorization/roleDefinitions/515c2055-d9d4-4321-b1b9-bd0c9a0f79fe'
  'Logic App Contributor': '/providers/Microsoft.Authorization/roleDefinitions/87a39d53-fc1b-424a-814c-f7e04687dc9e'
  'Managed Application Operator Role': '/providers/Microsoft.Authorization/roleDefinitions/c7393b34-138c-406f-901b-d8cf2b17e6ae'
  'Managed Applications Reader': '/providers/Microsoft.Authorization/roleDefinitions/b9331d33-8a36-4f8c-b097-4f54124fdb44'
  'Managed Identity Operator': '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
  'Managed Identity Contributor': '/providers/Microsoft.Authorization/roleDefinitions/e40ec5ca-96e0-45a2-b4ff-59039f2c2b59'
  'Management Group Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5d58bcaf-24a5-4b20-bdb6-eed9f69fbe4c'
  'Management Group Reader': '/providers/Microsoft.Authorization/roleDefinitions/ac63b705-f282-497d-ac71-919bf39d939d'
  'Monitoring Metrics Publisher': '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb'
  'Monitoring Reader': '/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  'Network Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  'Monitoring Contributor': '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  'New Relic APM Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5d28c62d-5b37-4476-8438-e587778df237'
  'Owner': '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  'Reader': '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  'Redis Cache Contributor': '/providers/Microsoft.Authorization/roleDefinitions/e0f68234-74aa-48ed-b826-c38b57376e17'
  'Reader and Data Access': '/providers/Microsoft.Authorization/roleDefinitions/c12c1c16-33a1-487b-954d-41c89c60f349'
  'Resource Policy Contributor': '/providers/Microsoft.Authorization/roleDefinitions/36243c78-bf99-498c-9df9-86d9f8d28608'
  'Scheduler Job Collections Contributor': '/providers/Microsoft.Authorization/roleDefinitions/188a0f2f-5c9e-469b-ae67-2aa5ce574b94'
  'Search Service Contributor': '/providers/Microsoft.Authorization/roleDefinitions/7ca78c08-252a-4471-8644-bb5ff32d4ba0'
  'Security Admin': '/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd'
  'Security Reader': '/providers/Microsoft.Authorization/roleDefinitions/39bc4728-0917-49c7-9d2c-d95423bc2eb4'
  'Spatial Anchors Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8bbe83f1-e2a6-4df7-8cb4-4e04d4e5c827'
  'Site Recovery Contributor': '/providers/Microsoft.Authorization/roleDefinitions/6670b86e-a3f7-4917-ac9b-5d6ab1be4567'
  'Site Recovery Operator': '/providers/Microsoft.Authorization/roleDefinitions/494ae006-db33-4328-bf46-533a6560a3ca'
  'Spatial Anchors Account Reader': '/providers/Microsoft.Authorization/roleDefinitions/5d51204f-eb77-4b1c-b86a-2ec626c49413'
  'Site Recovery Reader': '/providers/Microsoft.Authorization/roleDefinitions/dbaa88c4-0c30-4179-9fb3-46319faa6149'
  'Spatial Anchors Account Owner': '/providers/Microsoft.Authorization/roleDefinitions/70bbe301-9835-447d-afdd-19eb3167307c'
  'SQL Managed Instance Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4939a1f6-9ae0-4e48-a1e0-f2cbe897382d'
  'SQL DB Contributor': '/providers/Microsoft.Authorization/roleDefinitions/9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
  'SQL Security Manager': '/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3'
  'Storage Account Contributor': '/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'
  'SQL Server Contributor': '/providers/Microsoft.Authorization/roleDefinitions/6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437'
  'Storage Account Key Operator Service Role': '/providers/Microsoft.Authorization/roleDefinitions/81a9662b-bebf-436f-a333-f67b29880f12'
  'Storage Blob Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  'Storage Blob Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  'Storage Blob Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  'Storage Queue Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  'Storage Queue Data Message Processor': '/providers/Microsoft.Authorization/roleDefinitions/8a0f0c08-91a1-4084-bc3d-661d67233fed'
  'Storage Queue Data Message Sender': '/providers/Microsoft.Authorization/roleDefinitions/c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'
  'Storage Queue Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/19e7f393-937e-4f77-808e-94535e297925'
  'Support Request Contributor': '/providers/Microsoft.Authorization/roleDefinitions/cfd33db0-3dd1-45e3-aa9d-cdbdf3b6f24e'
  'Traffic Manager Contributor': '/providers/Microsoft.Authorization/roleDefinitions/a4b10055-b0c7-44c2-b00f-c7b5b3550cf7'
  'Virtual Machine Administrator Login': '/providers/Microsoft.Authorization/roleDefinitions/1c0163c0-47e6-4577-8991-ea5c82e286e4'
  'User Access Administrator': '/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  'Virtual Machine User Login': '/providers/Microsoft.Authorization/roleDefinitions/fb879df8-f326-4884-b1cf-06f3ad86be52'
  'Virtual Machine Contributor': '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  'Web Plan Contributor': '/providers/Microsoft.Authorization/roleDefinitions/2cc479cb-7b4d-49a8-b449-8c00fd0f0a4b'
  'Website Contributor': '/providers/Microsoft.Authorization/roleDefinitions/de139f84-1756-47ae-9be6-808fbbe84772'
  'Azure Service Bus Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419'
  'Azure Event Hubs Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/f526a384-b230-433a-b45c-95f59c4a2dec'
  'Attestation Contributor': '/providers/Microsoft.Authorization/roleDefinitions/bbf86eb8-f7b4-4cce-96e4-18cddf81d86e'
  'HDInsight Cluster Operator': '/providers/Microsoft.Authorization/roleDefinitions/61ed4efc-fab3-44fd-b111-e24485cc132a'
  'Cosmos DB Operator': '/providers/Microsoft.Authorization/roleDefinitions/230815da-be43-4aae-9cb4-875f7bd000aa'
  'Hybrid Server Resource Administrator': '/providers/Microsoft.Authorization/roleDefinitions/48b40c6e-82e0-4eb3-90d5-19e40f49b624'
  'Hybrid Server Onboarding': '/providers/Microsoft.Authorization/roleDefinitions/5d1e5ee4-7c68-4a71-ac8b-0739630a3dfb'
  'Azure Event Hubs Data Receiver': '/providers/Microsoft.Authorization/roleDefinitions/a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
  'Azure Event Hubs Data Sender': '/providers/Microsoft.Authorization/roleDefinitions/2b629674-e913-4c01-ae53-ef4638d8f975'
  'Azure Service Bus Data Receiver': '/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  'Azure Service Bus Data Sender': '/providers/Microsoft.Authorization/roleDefinitions/69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  'Storage File Data SMB Share Reader': '/providers/Microsoft.Authorization/roleDefinitions/aba4ae5f-2193-4029-9191-0cb91df5e314'
  'Storage File Data SMB Share Contributor': '/providers/Microsoft.Authorization/roleDefinitions/0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
  'Private DNS Zone Contributor': '/providers/Microsoft.Authorization/roleDefinitions/b12aa53e-6015-4669-85d0-8515ebb3ae7f'
  'Storage Blob Delegator': '/providers/Microsoft.Authorization/roleDefinitions/db58b8e5-c6ad-4a2a-8342-4190687cbf4a'
  'Desktop Virtualization User': '/providers/Microsoft.Authorization/roleDefinitions/1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
  'Storage File Data SMB Share Elevated Contributor': '/providers/Microsoft.Authorization/roleDefinitions/a7264617-510b-434b-a828-9731dc254ea7'
  'Blueprint Contributor': '/providers/Microsoft.Authorization/roleDefinitions/41077137-e803-4205-871c-5a86e6a753b4'
  'Blueprint Operator': '/providers/Microsoft.Authorization/roleDefinitions/437d2ced-4a38-4302-8479-ed2bcb43d090'
  'Azure Sentinel Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ab8e14d6-4a74-4a29-9ba8-549422addade'
  'Azure Sentinel Responder': '/providers/Microsoft.Authorization/roleDefinitions/3e150937-b8fe-4cfb-8069-0eaf05ecd056'
  'Azure Sentinel Reader': '/providers/Microsoft.Authorization/roleDefinitions/8d289c81-5878-46d4-8554-54e1e3d8b5cb'
  'Workbook Reader': '/providers/Microsoft.Authorization/roleDefinitions/b279062a-9be3-42a0-92ae-8b3cf002ec4d'
  'Workbook Contributor': '/providers/Microsoft.Authorization/roleDefinitions/e8ddcd69-c73f-4f9f-9844-4100522f16ad'
  'SignalR AccessKey Reader': '/providers/Microsoft.Authorization/roleDefinitions/04165923-9d83-45d5-8227-78b77b0a687e'
  'SignalR/Web PubSub Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8cf5e20a-e4b2-4e9d-b3a1-5ceb692c2761'
  'Azure Connected Machine Onboarding': '/providers/Microsoft.Authorization/roleDefinitions/b64e21ea-ac4e-4cdf-9dc9-5b892992bee7'
  'Azure Connected Machine Resource Administrator': '/providers/Microsoft.Authorization/roleDefinitions/cd570a14-e51a-42ad-bac8-bafd67325302'
  'Managed Services Registration assignment Delete Role': '/providers/Microsoft.Authorization/roleDefinitions/91c1777a-f3dc-4fae-b103-61d183457e46'
  'App Configuration Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
  'App Configuration Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071'
  'Kubernetes Cluster - Azure Arc Onboarding': '/providers/Microsoft.Authorization/roleDefinitions/34e09817-6cbe-4d01-b1a2-e0eac5743d41'
  'Experimentation Contributor': '/providers/Microsoft.Authorization/roleDefinitions/7f646f1b-fa08-80eb-a22b-edd6ce5c915c'
  'Cognitive Services QnA Maker Reader': '/providers/Microsoft.Authorization/roleDefinitions/466ccd10-b268-4a11-b098-b4849f024126'
  'Cognitive Services QnA Maker Editor': '/providers/Microsoft.Authorization/roleDefinitions/f4cc2bf9-21be-47a1-bdf1-5c5804381025'
  'Experimentation Administrator': '/providers/Microsoft.Authorization/roleDefinitions/7f646f1b-fa08-80eb-a33b-edd6ce5c915c'
  'Remote Rendering Administrator': '/providers/Microsoft.Authorization/roleDefinitions/3df8b902-2a6f-47c7-8cc5-360e9b272a7e'
  'Remote Rendering Client': '/providers/Microsoft.Authorization/roleDefinitions/d39065c4-c120-43c9-ab0a-63eed9795f0a'
  'Managed Application Contributor Role': '/providers/Microsoft.Authorization/roleDefinitions/641177b8-a67a-45b9-a033-47bc880bb21e'
  'Security Assessment Contributor': '/providers/Microsoft.Authorization/roleDefinitions/612c2aa1-cb24-443b-ac28-3ab7272de6f5'
  'Tag Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4a9ae827-6dc8-4573-8ac7-8239d42aa03f'
  'Integration Service Environment Developer': '/providers/Microsoft.Authorization/roleDefinitions/c7aa55d3-1abb-444a-a5ca-5e51e485d6ec'
  'Integration Service Environment Contributor': '/providers/Microsoft.Authorization/roleDefinitions/a41e2c5b-bd99-4a07-88f4-9bf657a760b8'
  'Azure Kubernetes Service Contributor Role': '/providers/Microsoft.Authorization/roleDefinitions/ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
  'Azure Digital Twins Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/d57506d4-4c8d-48b1-8587-93c323f6a5a3'
  'Azure Digital Twins Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/bcd981a7-7f74-457b-83e1-cceb9e632ffe'
  'Hierarchy Settings Administrator': '/providers/Microsoft.Authorization/roleDefinitions/350f8d15-c687-4448-8ae1-157740a3936d'
  'FHIR Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/5a1fc7df-4bf1-4951-a576-89034ee01acd'
  'FHIR Data Exporter': '/providers/Microsoft.Authorization/roleDefinitions/3db33094-8700-4567-8da5-1501d4e7e843'
  'FHIR Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/4c8d0bbc-75d3-4935-991f-5f3c56d81508'
  'FHIR Data Writer': '/providers/Microsoft.Authorization/roleDefinitions/3f88fce4-5892-4214-ae73-ba5294559913'
  'Experimentation Reader': '/providers/Microsoft.Authorization/roleDefinitions/49632ef5-d9ac-41f4-b8e7-bbe587fa74a1'
  'Object Understanding Account Owner': '/providers/Microsoft.Authorization/roleDefinitions/4dd61c23-6743-42fe-a388-d8bdd41cb745'
  'Azure Maps Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8f5e0ce6-4f7b-4dcf-bddf-e6f48634a204'
  'Cognitive Services Custom Vision Contributor': '/providers/Microsoft.Authorization/roleDefinitions/c1ff6cc2-c111-46fe-8896-e0ef812ad9f3'
  'Cognitive Services Custom Vision Deployment': '/providers/Microsoft.Authorization/roleDefinitions/5c4089e1-6d96-4d2f-b296-c1bc7137275f'
  'Cognitive Services Custom Vision Labeler': '/providers/Microsoft.Authorization/roleDefinitions/88424f51-ebe7-446f-bc41-7fa16989e96c'
  'Cognitive Services Custom Vision Reader': '/providers/Microsoft.Authorization/roleDefinitions/93586559-c37d-4a6b-ba08-b9f0940c2d73'
  'Cognitive Services Custom Vision Trainer': '/providers/Microsoft.Authorization/roleDefinitions/0a5ae4ab-0d65-4eeb-be61-29fc9b54394b'
  'Key Vault Administrator': '/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
  'Key Vault Crypto Officer': '/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  'Key Vault Crypto User': '/providers/Microsoft.Authorization/roleDefinitions/12338af0-0e69-4776-bea7-57ae8d297424'
  'Key Vault Secrets Officer': '/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  'Key Vault Secrets User': '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
  'Key Vault Certificates Officer': '/providers/Microsoft.Authorization/roleDefinitions/a4417e6f-fecd-4de8-b567-7b0420556985'
  'Key Vault Reader': '/providers/Microsoft.Authorization/roleDefinitions/21090545-7ca7-4776-b22c-e363652d74d2'
  'Key Vault Crypto Service Encryption User': '/providers/Microsoft.Authorization/roleDefinitions/e147488a-f6f5-4113-8e2d-b22465e65bf6'
  'Azure Arc Kubernetes Viewer': '/providers/Microsoft.Authorization/roleDefinitions/63f0a09d-1495-4db4-a681-037d84835eb4'
  'Azure Arc Kubernetes Writer': '/providers/Microsoft.Authorization/roleDefinitions/5b999177-9696-4545-85c7-50de3797e5a1'
  'Azure Arc Kubernetes Cluster Admin': '/providers/Microsoft.Authorization/roleDefinitions/8393591c-06b9-48a2-a542-1bd6b377f6a2'
  'Azure Arc Kubernetes Admin': '/providers/Microsoft.Authorization/roleDefinitions/dffb1e0c-446f-4dde-a09f-99eb5cc68b96'
  'Azure Kubernetes Service RBAC Cluster Admin': '/providers/Microsoft.Authorization/roleDefinitions/b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
  'Azure Kubernetes Service RBAC Admin': '/providers/Microsoft.Authorization/roleDefinitions/3498e952-d568-435e-9b2c-8d77e338d7f7'
  'Azure Kubernetes Service RBAC Reader': '/providers/Microsoft.Authorization/roleDefinitions/7f6c6a51-bcf8-42ba-9220-52d62157d7db'
  'Azure Kubernetes Service RBAC Writer': '/providers/Microsoft.Authorization/roleDefinitions/a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb'
  'Services Hub Operator': '/providers/Microsoft.Authorization/roleDefinitions/82200a5b-e217-47a5-b665-6d8765ee745b'
  'Object Understanding Account Reader': '/providers/Microsoft.Authorization/roleDefinitions/d18777c0-1514-4662-8490-608db7d334b6'
  'Azure Arc Enabled Kubernetes Cluster User Role': '/providers/Microsoft.Authorization/roleDefinitions/00493d72-78f6-4148-b6c5-d3ce8e4799dd'
  'SignalR REST API Owner': '/providers/Microsoft.Authorization/roleDefinitions/fd53cd77-2268-407a-8f46-7e7863d0f521'
  'Collaborative Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/daa9e50b-21df-454c-94a6-a8050adab352'
  'Device Update Reader': '/providers/Microsoft.Authorization/roleDefinitions/e9dba6fb-3d52-4cf0-bce3-f06ce71b9e0f'
  'Device Update Administrator': '/providers/Microsoft.Authorization/roleDefinitions/02ca0879-e8e4-47a5-a61e-5c618b76e64a'
  'Device Update Content Administrator': '/providers/Microsoft.Authorization/roleDefinitions/0378884a-3af5-44ab-8323-f5b22f9f3c98'
  'Device Update Deployments Administrator': '/providers/Microsoft.Authorization/roleDefinitions/e4237640-0e3d-4a46-8fda-70bc94856432'
  'Device Update Deployments Reader': '/providers/Microsoft.Authorization/roleDefinitions/49e2f5d2-7741-4835-8efa-19e1fe35e47f'
  'Device Update Content Reader': '/providers/Microsoft.Authorization/roleDefinitions/d1ee9a80-8b14-47f0-bdc2-f4a351625a7b'
  'Cognitive Services Metrics Advisor Administrator': '/providers/Microsoft.Authorization/roleDefinitions/cb43c632-a144-4ec5-977c-e80c4affc34a'
  'Cognitive Services Metrics Advisor User': '/providers/Microsoft.Authorization/roleDefinitions/3b20f47b-3825-43cb-8114-4bd2201156a8'
  'AgFood Platform Service Reader': '/providers/Microsoft.Authorization/roleDefinitions/7ec7ccdc-f61e-41fe-9aaf-980df0a44eba'
  'AgFood Platform Service Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8508508a-4469-4e45-963b-2518ee0bb728'
  'AgFood Platform Service Admin': '/providers/Microsoft.Authorization/roleDefinitions/f8da80de-1ff9-4747-ad80-a19b7f6079e3'
  'Managed HSM contributor': '/providers/Microsoft.Authorization/roleDefinitions/18500a29-7fe2-46b2-a342-b16a415e101d'
  'Security Detonation Chamber Submitter': '/providers/Microsoft.Authorization/roleDefinitions/0b555d9b-b4a7-4f43-b330-627f0e5be8f0'
  'SignalR REST API Reader': '/providers/Microsoft.Authorization/roleDefinitions/ddde6b66-c0df-4114-a159-3618637b3035'
  'SignalR Service Owner': '/providers/Microsoft.Authorization/roleDefinitions/7e4f1700-ea5a-4f59-8f37-079cfe29dce3'
  'Reservation Purchaser': '/providers/Microsoft.Authorization/roleDefinitions/f7b75c60-3036-4b75-91c3-6b41c27c1689'
  'Storage Account Backup Contributor Role': '/providers/Microsoft.Authorization/roleDefinitions/e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1'
  'Experimentation Metric Contributor': '/providers/Microsoft.Authorization/roleDefinitions/6188b7c9-7d01-4f99-a59f-c88b630326c0'
  'Project Babylon Data Curator': '/providers/Microsoft.Authorization/roleDefinitions/9ef4ef9c-a049-46b0-82ab-dd8ac094c889'
  'Project Babylon Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/c8d896ba-346d-4f50-bc1d-7d1c84130446'
  'Project Babylon Data Source Administrator': '/providers/Microsoft.Authorization/roleDefinitions/05b7651b-dc44-475e-b74d-df3db49fae0f'
  'Application Group Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ca6382a4-1721-4bcf-a114-ff0c70227b6b'
  'Desktop Virtualization Reader': '/providers/Microsoft.Authorization/roleDefinitions/49a72310-ab8d-41df-bbb0-79b649203868'
  'Desktop Virtualization Contributor': '/providers/Microsoft.Authorization/roleDefinitions/082f0a83-3be5-4ba1-904c-961cca79b387'
  'Desktop Virtualization Workspace Contributor': '/providers/Microsoft.Authorization/roleDefinitions/21efdde3-836f-432b-bf3d-3e8e734d4b2b'
  'Desktop Virtualization User Session Operator': '/providers/Microsoft.Authorization/roleDefinitions/ea4bfff8-7fb4-485a-aadd-d4129a0ffaa6'
  'Desktop Virtualization Session Host Operator': '/providers/Microsoft.Authorization/roleDefinitions/2ad6aaab-ead9-4eaa-8ac5-da422f562408'
  'Desktop Virtualization Host Pool Reader': '/providers/Microsoft.Authorization/roleDefinitions/ceadfde2-b300-400a-ab7b-6143895aa822'
  'Desktop Virtualization Host Pool Contributor': '/providers/Microsoft.Authorization/roleDefinitions/e307426c-f9b6-4e81-87de-d99efb3c32bc'
  'Desktop Virtualization Application Group Reader': '/providers/Microsoft.Authorization/roleDefinitions/aebf23d0-b568-4e86-b8f9-fe83a2c6ab55'
  'Desktop Virtualization Application Group Contributor': '/providers/Microsoft.Authorization/roleDefinitions/86240b0e-9422-4c43-887b-b61143f32ba8'
  'Desktop Virtualization Workspace Reader': '/providers/Microsoft.Authorization/roleDefinitions/0fa44ee9-7a7d-466b-9bb2-2bf446b1204d'
  'Disk Backup Reader': '/providers/Microsoft.Authorization/roleDefinitions/3e5e47e6-65f7-47ef-90b5-e5dd4d455f24'
  'Disk Restore Operator': '/providers/Microsoft.Authorization/roleDefinitions/b50d9833-a0cb-478e-945f-707fcc997c13'
  'Disk Snapshot Contributor': '/providers/Microsoft.Authorization/roleDefinitions/7efff54f-a5b4-42b5-a1c5-5411624893ce'
  'Microsoft.Kubernetes connected cluster role': '/providers/Microsoft.Authorization/roleDefinitions/5548b2cf-c94c-4228-90ba-30851930a12f'
  'Security Detonation Chamber Submission Manager': '/providers/Microsoft.Authorization/roleDefinitions/a37b566d-3efa-4beb-a2f2-698963fa42ce'
  'Security Detonation Chamber Publisher': '/providers/Microsoft.Authorization/roleDefinitions/352470b3-6a9c-4686-b503-35deb827e500'
  'Collaborative Runtime Operator': '/providers/Microsoft.Authorization/roleDefinitions/7a6f0e70-c033-4fb1-828c-08514e5f4102'
  'CosmosRestoreOperator': '/providers/Microsoft.Authorization/roleDefinitions/5432c526-bc82-444a-b7ba-57c5b0b5b34f'
  'FHIR Data Converter': '/providers/Microsoft.Authorization/roleDefinitions/a1705bd2-3a8f-45a5-8683-466fcfd5cc24'
  'Azure Sentinel Automation Contributor': '/providers/Microsoft.Authorization/roleDefinitions/f4c81013-99ee-4d62-a7ee-b3f1f648599a'
  'Quota Request Operator': '/providers/Microsoft.Authorization/roleDefinitions/0e5f05e5-9ab9-446b-b98d-1e2157c94125'
  'EventGrid Contributor': '/providers/Microsoft.Authorization/roleDefinitions/1e241071-0855-49ea-94dc-649edcd759de'
  'Security Detonation Chamber Reader': '/providers/Microsoft.Authorization/roleDefinitions/28241645-39f8-410b-ad48-87863e2951d5'
  'Object Anchors Account Reader': '/providers/Microsoft.Authorization/roleDefinitions/4a167cdf-cb95-4554-9203-2347fe489bd9'
  'Object Anchors Account Owner': '/providers/Microsoft.Authorization/roleDefinitions/ca0835dd-bacc-42dd-8ed2-ed5e7230d15b'
  'WorkloadBuilder Migration Agent Role': '/providers/Microsoft.Authorization/roleDefinitions/d17ce0a2-0697-43bc-aac5-9113337ab61c'
  'Azure Spring Cloud Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/b5537268-8956-4941-a8f0-646150406f0c'
  'Cognitive Services Speech User': '/providers/Microsoft.Authorization/roleDefinitions/f2dc8367-1007-4938-bd23-fe263f013447'
  'Cognitive Services Speech Contributor': '/providers/Microsoft.Authorization/roleDefinitions/0e75ca1e-0464-4b4d-8b93-68208a576181'
  'Cognitive Services Face Recognizer': '/providers/Microsoft.Authorization/roleDefinitions/9894cab4-e18a-44aa-828b-cb588cd6f2d7'
  'Media Services Account Administrator': '/providers/Microsoft.Authorization/roleDefinitions/054126f8-9a2b-4f1c-a9ad-eca461f08466'
  'Media Services Live Events Administrator': '/providers/Microsoft.Authorization/roleDefinitions/532bc159-b25e-42c0-969e-a1d439f60d77'
  'Media Services Media Operator': '/providers/Microsoft.Authorization/roleDefinitions/e4395492-1534-4db2-bedf-88c14621589c'
  'Media Services Policy Administrator': '/providers/Microsoft.Authorization/roleDefinitions/c4bba371-dacd-4a26-b320-7250bca963ae'
  'Media Services Streaming Endpoints Administrator': '/providers/Microsoft.Authorization/roleDefinitions/99dba123-b5fe-44d5-874c-ced7199a5804'
  'Stream Analytics Query Tester': '/providers/Microsoft.Authorization/roleDefinitions/1ec5b3c1-b17e-4e25-8312-2acb3c3c5abf'
  'AnyBuild Builder': '/providers/Microsoft.Authorization/roleDefinitions/a2138dac-4907-4679-a376-736901ed8ad8'
  'IoT Hub Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/b447c946-2db7-41ec-983d-d8bf3b1c77e3'
  'IoT Hub Twin Contributor': '/providers/Microsoft.Authorization/roleDefinitions/494bdba2-168f-4f31-a0a1-191d2f7c028c'
  'IoT Hub Registry Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4ea46cd5-c1b2-4a8e-910b-273211f9ce47'
  'IoT Hub Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4fc6c259-987e-4a07-842e-c321cc9d413f'
  'Test Base Reader': '/providers/Microsoft.Authorization/roleDefinitions/15e0f5a1-3450-4248-8e25-e2afe88a9e85'
  'Search Index Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/1407120a-92aa-4202-b7e9-c0e197c71c8f'
  'Search Index Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  'Storage Table Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/76199698-9eea-4c19-bc75-cec21354c6b6'
  'Storage Table Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  'DICOM Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/e89c7a3c-2f64-4fa1-a847-3e4c9ba4283a'
  'DICOM Data Owner': '/providers/Microsoft.Authorization/roleDefinitions/58a3b984-7adf-4c20-983a-32417c86fbc8'
  'EventGrid Data Sender': '/providers/Microsoft.Authorization/roleDefinitions/d5a91429-5739-47e2-a06b-3470a27159e7'
  'Disk Pool Operator': '/providers/Microsoft.Authorization/roleDefinitions/60fc6e62-5479-42d4-8bf4-67625fcc2840'
  'AzureML Data Scientist': '/providers/Microsoft.Authorization/roleDefinitions/f6c7c914-8db3-469d-8ca1-694a8f32e121'
  'Grafana Admin': '/providers/Microsoft.Authorization/roleDefinitions/22926164-76b3-42b3-bc55-97df8dab3e41'
  'Azure Connected SQL Server Onboarding': '/providers/Microsoft.Authorization/roleDefinitions/e8113dce-c529-4d33-91fa-e9b972617508'
  'Azure Relay Sender': '/providers/Microsoft.Authorization/roleDefinitions/26baccc8-eea7-41f1-98f4-1762cc7f685d'
  'Azure Relay Owner': '/providers/Microsoft.Authorization/roleDefinitions/2787bf04-f1f5-4bfe-8383-c8a24483ee38'
  'Azure Relay Listener': '/providers/Microsoft.Authorization/roleDefinitions/26e0b698-aa6d-4085-9386-aadae190014d'
  'Grafana Viewer': '/providers/Microsoft.Authorization/roleDefinitions/60921a7e-fef1-4a43-9b16-a26c52ad4769'
  'Grafana Editor': '/providers/Microsoft.Authorization/roleDefinitions/a79a5197-3a5c-4973-a920-486035ffd60f'
  'Automation Contributor': '/providers/Microsoft.Authorization/roleDefinitions/f353d9bd-d4a6-484e-a77a-8050b599b867'
  'Kubernetes Extension Contributor': '/providers/Microsoft.Authorization/roleDefinitions/85cb6faf-e071-4c9b-8136-154b5a04f717'
  'Device Provisioning Service Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/10745317-c249-44a1-a5ce-3a4353c0bbd8'
  'Device Provisioning Service Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/dfce44e4-17b7-4bd1-a6d1-04996ec95633'
  'CodeSigning Certificate Profile Signer': '/providers/Microsoft.Authorization/roleDefinitions/2837e146-70d7-4cfd-ad55-7efa6464f958'
  'Azure Spring Cloud Service Registry Reader': '/providers/Microsoft.Authorization/roleDefinitions/cff1b556-2399-4e7e-856d-a8f754be7b65'
  'Azure Spring Cloud Service Registry Contributor': '/providers/Microsoft.Authorization/roleDefinitions/f5880b48-c26d-48be-b172-7927bfa1c8f1'
  'Azure Spring Cloud Config Server Reader': '/providers/Microsoft.Authorization/roleDefinitions/d04c6db6-4947-4782-9e91-30a88feb7be7'
  'Azure Spring Cloud Config Server Contributor': '/providers/Microsoft.Authorization/roleDefinitions/a06f5c24-21a7-4e1a-aa2b-f19eb6684f5b'
  'Azure VM Managed identities restore Contributor': '/providers/Microsoft.Authorization/roleDefinitions/6ae96244-5829-4925-a7d3-5975537d91dd'
  'Azure Maps Search and Render Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/6be48352-4f82-47c9-ad5e-0acacefdb005'
  'Azure Maps Contributor': '/providers/Microsoft.Authorization/roleDefinitions/dba33070-676a-4fb0-87fa-064dc56ff7fb'
}

var roleDefinitionId_var = (contains(builtInRoleNames_var, roleDefinitionIdOrName) ? builtInRoleNames_var[roleDefinitionIdOrName] : roleDefinitionIdOrName)

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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscriptionId, resourceGroupName, roleDefinitionId_var, principalId)
  properties: {
    roleDefinitionId: roleDefinitionId_var
    principalId: principalId
    description: !empty(description) ? description : null
    principalType: !empty(principalType) ? any(principalType) : null
    delegatedManagedIdentityResourceId: !empty(delegatedManagedIdentityResourceId) ? delegatedManagedIdentityResourceId : null
    conditionVersion: !empty(conditionVersion) && !empty(condition) ? conditionVersion : null
    condition: !empty(condition) ? condition : null
  }
}

@sys.description('The GUID of the Role Assignment')
output name string = roleAssignment.name

@sys.description('The resource ID of the Role Assignment')
output scope string = resourceGroup().id

@sys.description('The scope this Role Assignment applies to')
output resourceId string = az.resourceId(resourceGroupName, 'Microsoft.Authorization/roleAssignments', roleAssignment.name)

@sys.description('The name of the resource group the role assignment was applied at')
output resourceGroupName string = resourceGroup().name
