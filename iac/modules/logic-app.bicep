@description('Logic App Name')
param logicAppName string
@description('The location of the resources')
param location string
@description('Tags for the resources')
param tags object
@description('The Connections for this logic app')
param logicAppConnection object
@description('The secret to sign payloads coming from Snyk to verify they are authentic')
@secure()
param snykWebhookSecret string
@description('Your Snyk Organisation Id')
param snykOrgId string
@description('The Snyk API token')
@secure()
param snykApiToken string
@description('Snyk Issue Severity')
@allowed([ 'low', 'medium', 'high', 'critical' ])
param snykSeverity string = 'high'
@description('The Resource Id of the function application')
param functionId string
@description('The Project name in Azure DevOps')
param projectName string
@description('The Organisation name in Azure DevOps')
param account string
@description('SnykApi Base Address')
param snykBaseAddress string = 'https://snyk.io/api/v1/org'

var synkSeverties = {
  low: {
    values: [ 'low', 'medium', 'high', 'critical' ]
  }
  medium: {
    values: [ 'medium', 'high', 'critical' ]
  }
  high: {
    values: [ 'high', 'critical' ]
  }
  critical: {
    values: [ 'critical' ]
  }
}

resource logicAppConnectionResources 'Microsoft.Web/connections@2016-06-01' = {
  name: logicAppConnection.name
  location: location
  properties: {
    displayName: logicAppConnection.name
    parameterValues: logicAppConnection.parameterValues
    api: {
      name: logicAppConnection.name
      displayName: logicAppConnection.displayName
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${logicAppConnection.name}'
    }
  }
}

resource workflowResources 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Setup_Snyk_Webhook: {
          type: 'HttpWebhook'
          inputs: {
            subscribe: {
              body: {
                secret: snykWebhookSecret
                url: '@listCallbackUrl()'
              }
              headers: {
                Authorization: 'token ${snykApiToken}'
                'Content-Type': 'application/json;charset=utf-8'
              }
              method: 'POST'
              uri: '${snykBaseAddress}/${snykOrgId}/webhooks'
            }
            unsubscribe: {
              headers: {
                Authorization: 'token ${snykApiToken}'
                'Content-Type': 'application/json;charset=utf-8'
              }
              method: 'DELETE'
              uri: '@{concat(\'${snykBaseAddress}/${snykOrgId}/webhooks/\',triggerOutputs().subscribe.body.id)}'
            }
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'inputs'
                'outputs'
              ]
            }
          }
        }
      }
      actions: {
        Check_for_Webhook_Ping: {
          actions: {
            Terminate: {
              runAfter: {
              }
              type: 'Terminate'
              inputs: {
                runStatus: 'Succeeded'
              }
            }
          }
          runAfter: {
          }
          else: {
            actions: {
              Loop_New_Issues: {
                foreach: '@body(\'Parse_JSON\')?[\'newIssues\']'
                actions: {
                  Check_Severity_Level: {
                    actions: {
                      Create_a_work_item: {
                        runAfter: {
                        }
                        type: 'ApiConnection'
                        inputs: {
                          body: {
                            description: '<p>@{items(\'Loop_New_Issues\')?[\'issueData\']?[\'description\']}</p>'
                            title: '@{items(\'Loop_New_Issues\')?[\'issueData\']?[\'title\']}'
                          }
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'visualstudioteamservices\'][\'connectionId\']'
                            }
                          }
                          method: 'patch'
                          path: '/@{encodeURIComponent(\'${projectName}\')}/_apis/wit/workitems/$Bug'
                          queries: {
                            account: account
                          }
                        }
                      }
                    }
                    runAfter: {
                    }
                    expression: {
                      and: [
                        {
                          contains: [
                            '${synkSeverties[snykSeverity].values}'
                            '@items(\'Loop_New_Issues\')?[\'issueData\']?[\'severity\']'
                          ]
                        }
                      ]
                    }
                    type: 'If'
                  }
                }
                runAfter: {
                  Parse_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'Foreach'
              }
              Parse_JSON: {
                runAfter: {
                  ValidateRequest: [
                    'Succeeded'
                  ]
                }
                type: 'ParseJson'
                inputs: {
                  content: '@triggerBody()'
                  schema: {
                    properties: {
                      group: {
                        properties: {
                        }
                        type: 'object'
                      }
                      newIssues: {
                        type: 'array'
                      }
                      org: {
                        properties: {
                        }
                        type: 'object'
                      }
                      project: {
                        properties: {
                        }
                        type: 'object'
                      }
                      removedIssues: {
                        type: 'array'
                      }
                    }
                    type: 'object'
                  }
                }
              }
              ValidateRequest: {
                runAfter: {
                }
                type: 'Function'
                inputs: {
                  body: '@triggerBody()'
                  function: {
                    id: functionId
                  }
                  headers: '@addProperty(triggerOutputs()[\'headers\'], \'x-logicapp-secret\', \'${snykWebhookSecret}\')'
                  method: 'POST'
                }
              }
            }
          }
          expression: {
            or: [
              {
                equals: [
                  '@coalesce(triggerOutputs()?[\'headers\']?[\'X-Snyk-Event\'],\'\')'
                  ''
                ]
              }
              {
                contains: [
                  '@triggerOutputs()?[\'headers\']?[\'X-Snyk-Event\']'
                  'ping'
                ]
              }
            ]
          }
          type: 'If'
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          '${logicAppConnection.name}': {
            connectionName: logicAppConnection.name
            connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${logicAppConnection.name}'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${logicAppConnection.name}'
          }
        }
      }
    }
  }
  dependsOn: [
    logicAppConnectionResources
  ]
}
