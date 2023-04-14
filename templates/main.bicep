targetScope = 'subscription'

@description('Globally unique name of the function app to create.')
param appName string
@description('Name of the hosting plan to create and put the function app within. Can\'t be an existing one.')
param hostingPlanName string
@description('Name of the resource group to put the deployed resources in.')
param resourceGroupName string
@description('Name of Azure Region to deploy resources to.')
param region string
@description('GUID of the AAD group to give Admin access to Key Vault data plane.')
param keyVaultAdminsGroupGuid string
@description('Full resource id of an existing Log Analytics Workspace to use. Leave empty to create a new.')
param existingLogAnalyticsWorkspaceResourceId string = ''
@description('URL to repo to import into the app. Leave empty to skip.')
param gitRepoUrl string = ''
@description('GUID of the Tenant')
param tenantID string = tenant().tenantId
param now string = utcNow()

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: region
}

module azpwshfnapp 'modules/azure-function-pwsh-app.bicep' = {
  scope: rg
  name: take('fnapp_${appName}_${now}',64)
  params: {
    appName: appName
    hostingPlanName: hostingPlanName 
    keyVaultAdminsGroupGuid: keyVaultAdminsGroupGuid
    existingLogAnalyticsWorkspaceResourceId: existingLogAnalyticsWorkspaceResourceId
    gitRepoUrl: gitRepoUrl
    location: region
    tenantID: tenantID
  }
}

output fnAppRecId string = azpwshfnapp.outputs.fnAppRecId
