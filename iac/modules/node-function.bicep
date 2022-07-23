@description('The tags for the resources')
param tags object
@description('The location for the resources')
param location string
@description('The name of the storage account')
@maxLength(24)
@minLength(3)
param storeageName string
@description('The application insights name')
param appInsightsName string
@description('The hosting plan name')
param hostingPlanName string
@description('The function app name')
param funcAppName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storeageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
  tags: tags
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: tags
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
  tags: tags
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: funcAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: true
    siteConfig: {
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
      minTlsVersion: '1.2'
      http20Enabled: true 
      linuxFxVersion: 'NODE|16'
    }
  }
  dependsOn: [
    storageAccount
    appInsights
  ]
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

resource functionAppAppsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${functionApp.name}/appsettings'
  properties: {
    AzureWebJobsStorage: storageConnectionString
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
    WEBSITE_CONTENTSHARE: toLower(functionApp.name)
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    WEBSITE_RUN_FROM_PACKAGE: 1
  }
}

output name string = functionApp.name
output id string = functionApp.id
