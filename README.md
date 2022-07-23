# Introduction

A while ago I wrote a [blog post](https://codingwithtaz.blog/2021/08/02/create-issues-in-azure-devops-via-snyk-api/) about creating issues in Azure DevOps via the Snyk API using an Azure Logic App.
## Purpose

The aim of this project is to use IaC to create resources in Azure based on the above blog post with improvements allowing issues above a particular level to create issues rather than a single level and deploy using a pipeline.

- Register a webhook to your Snyk Organization via the API
- Validate incoming payloads are from Snyk
- For all new issues identified create a new Azure DevOps Work Item


## Code

The code is split into multiple folders:
- iac - Infrastructure as Code written in Bicep
- api - Azure Function to perform the validation of the incoming payloads

```text
|- iac
|  | - modules
|  |   | - naming.bicep
|  |   | - node-function.bicep
|  |   | - logic-app.bicep
|  | deploy_func.bicep
|  | deploy_logic.bicep
|- api
|  | - ValidateRequest
|  |   | function.json
|  |   | index.ts
|  | host.json
|  | package-lock.json
|  | package.json
|  | tsconfig.json
| azure-pipelines.yml
| create-parameters-file.yml
| func-params.yml
| logic-params.yml
```

## Deployment

The resources can be deployed using Azure Pipelines defined by azure-pipelines.yml

To deploy without the pipeline you need to perform the following actions in order

- Deploy Azure Function App
- Deploy the Azure Function Code
- Deploy the Logic App

__Note__: Once deployed you will need to authorize the connection to Azure DevOps