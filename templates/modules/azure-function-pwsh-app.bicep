@description('Name of the function app to create. This needs to be globally unique')
param appName string
@description('Name of the hosting plan to create and put the function app within. Can\'t be an existing one.')
param hostingPlanName string
@description('GUID of the AAD group to give Admin access to Key Vault data plane.')
param keyVaultAdminsGroupGuid string
@description('Full resource id of an existing Log Analytics Workspace to use, else a new will be created.')
param existingLogAnalyticsWorkspaceResourceId string = ''
@description('URL to repo to import into the app. Leave empty to skip.')
param gitRepoUrl string = ''
@description('GUID of the Tenant')
param tenantID string = tenant().tenantId
param location string = resourceGroup().location

// Prettify
var storageAccountName = toLower(take(appName, 24))
var functionAppName = toLower(take(appName, 32))
var hstPlanName = toLower(hostingPlanName)
var keyVaultName = toLower(take(appName, 24))
var applicationInsightsName = functionAppName

var keyVaultSecretOfficer = '/providers/Microsoft.Authorization/RoleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // Key Vault Secrets Officer
var keyVaultAdmin = '/providers/Microsoft.Authorization/RoleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
var azFilesShareName = 'azFunction'

var blobPermissions = [
  {
    name: guid('stBlobOwner-${subscription().id}-${resourceGroup().id}-${storageAccount.id}')
    roleDefinitionId: '/providers/Microsoft.Authorization/RoleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
  }
  {
    name: guid('stContrib-${subscription().id}-${resourceGroup().id}-${storageAccount.id}')
    roleDefinitionId: '/providers/Microsoft.Authorization/RoleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  }
  {
    name: guid('stQueContrib-${subscription().id}-${resourceGroup().id}-${storageAccount.id}')
    roleDefinitionId: '/providers/Microsoft.Authorization/RoleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Storage Queue Data Contributor
  }
  {
    name: guid('stTabContrib-${subscription().id}-${resourceGroup().id}-${storageAccount.id}')
    roleDefinitionId: '/providers/Microsoft.Authorization/RoleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
  }
]

resource keyVaultSecretOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

resource keyVaultAdminRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource azFuncFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: toLower('${storageAccount.name}/default/${azFilesShareName}')
  properties: {
    accessTier: 'Hot'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hstPlanName
  location: location
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
  properties: {
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    maximumElasticWorkerCount: 1
  }
}

resource funcApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    clientAffinityEnabled: true
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      powerShellVersion: '7.2'
      ftpsState: 'Disabled'
    }
  }
  resource sets 'config' = {
    name: 'appsettings'
    properties: {
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'powershell'
      AzureWebJobsStorage__accountname: storageAccount.name
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${keyVault::azFileConString.properties.secretUri})'
      WEBSITE_CONTENTSHARE: toLower(azFilesShareName)
      WEBSITE_SKIP_CONTENTSHARE_VALIDATION: '1'
      AzureWebJobsSecretStorageType: 'keyvault'
      AzureWebJobsSecretStorageKeyVaultUri: keyVault.properties.vaultUri
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
      WEBSITE_RUN_FROM_PACKAGE: '1'
      AppSettingDummySecret: 'This_Secret_Is_Stored_In_AppSettings'
      KeyVaultDummySecret: '@Microsoft.KeyVault(SecretUri=${keyVault::KeyVaultDummySecret.properties.secretUri})'
    }
  }
  resource repo 'sourcecontrols@2022-09-01' = if (!empty(gitRepoUrl)) {
    name: 'web'
    properties: {
      repoUrl: gitRepoUrl
      branch: 'main'
      isManualIntegration: true
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantID
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true
  }
  resource azFileConString 'secrets' = {
    name: 'azFileConString'
    properties: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    }
  }
  resource AzureWebJobsStorage 'secrets' = {
    name: 'AzureWebJobsStorage'
    properties: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    }
  }
  resource KeyVaultDummySecret 'secrets' = {
    name: 'KeyVaultDummySecret'
    properties: {
      value: 'This_Secret_Is_Stored_In_KeyVault'
    }
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (empty(existingLogAnalyticsWorkspaceResourceId)) {
  name: hstPlanName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30

  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: empty(existingLogAnalyticsWorkspaceResourceId) ? law.id : existingLogAnalyticsWorkspaceResourceId
  }
}

// Permissions for APP in keyVault
resource keyVaultPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('SecOfficer-${subscription().id}-${resourceGroup().id}-${keyVault.id}-${keyVaultSecretOfficer}')
  scope: keyVault
  properties: {
    principalType: 'ServicePrincipal'
    principalId: funcApp.identity.principalId
    roleDefinitionId: keyVaultSecretOfficerRoleDefinition.id
  }
}

// Permissions for Admins in keyVault
resource keyVaultACAdminPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('KVAdminOfficer-${subscription().id}-${resourceGroup().id}-${keyVault.id}-${keyVaultAdmin}')
  scope: keyVault
  properties: {
    principalId: keyVaultAdminsGroupGuid
    roleDefinitionId: keyVaultAdminRoleDefinition.id
  }
}

// Permissions for APP in STORAGE
resource storageAccountPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for perm in blobPermissions: {
  name: guid(perm.name, perm.roleDefinitionId)
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: funcApp.identity.principalId
    roleDefinitionId: perm.roleDefinitionId
  }
}]

output fnAppRecId string = funcApp.id
