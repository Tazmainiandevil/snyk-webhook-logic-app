@description('The tags for the resources')
param tags object = {
  purpose: 'snyk api validation'
}
@description('The location for the resources')
param location string = resourceGroup().location
@description('Application Name')
param appName string = 'myapp'
@description('The environment e.g. dev, qa, prod')
param env string = 'dev'

module namingModule 'modules/naming.bicep' = {
  name: 'namingDeploy'
  params: {
    appName: appName
    env: env
    location: location
  }
}

module functionDeploy 'modules/node-function.bicep' = {
  name: 'functionDeploy'
  params: {
    appInsightsName: replace(namingModule.outputs.resourceTemplate, '[ResourceType]', 'appi')
    funcAppName: replace(namingModule.outputs.resourceTemplate, '[ResourceType]', 'func')
    hostingPlanName: replace(namingModule.outputs.resourceTemplate, '[ResourceType]', 'plan')
    storeageName: namingModule.outputs.storageName
    tags: tags
    location: location
  }
  dependsOn: [
    namingModule
  ]
}

output functionName string = functionDeploy.outputs.name
output functionId string = functionDeploy.outputs.id
