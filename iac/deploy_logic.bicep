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
@description('The secret to sign payloads coming from Snyk to verify they are authentic')
@secure()
param snykWebhookSecret string
@description('Your Snyk Organisation Id')
param snykOrgId string
@description('The Snyk API token')
@secure()
param snykApiToken string
@description('The Resource Id of the function application')
param functionId string
@description('The Project name in Azure DevOps')
param projectName string
@description('The Organisation name in Azure DevOps')
param account string
@description('Snyk Issue Severity')
@allowed(['low','medium','high','critical'])
param snykSeverity string = 'high'

module namingModule 'modules/naming.bicep' = {
  name: 'namingDeploy'
  params: {
    appName: appName
    env: env
    location: location
  }
}

module logicAppDeploy 'modules/logic-app.bicep' = {
  name: 'logicAppDeploy'
  params: {
    location: location
    tags: tags
    snykWebhookSecret: snykWebhookSecret
    snykOrgId: snykOrgId
    snykApiToken: snykApiToken
    snykSeverity: snykSeverity
    account: account
    projectName: projectName
    functionId: functionId
    logicAppName: replace(namingModule.outputs.resourceTemplate, '[ResourceType]', 'logic')
    logicAppConnection:{
        name: 'visualstudioteamservices'
        displayName: 'Azure DevOps'
        parameterValues: {}
      }    
  }

  dependsOn: [
    namingModule
  ]
}
