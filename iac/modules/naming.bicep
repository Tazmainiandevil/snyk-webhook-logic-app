@description('The application name')
param appName string
@description('The environment name')
param env string
@description('The location')
param location string
@description('Index for the resource')
param index string = ''
@description('The separator to use to make the naming convention')
param separator string = '-'

var shortNames = {
  westeurope: {
    shortName: 'weu'
  }
  northeurope: {
    shortName: 'neu'
  }
  uksouth: {
    shortName: 'uks'
  }
  ukwest: {
    shortName: 'ukw'
  }
  westus: {
    shortName: 'wus'
  }
  eastus: {
    shortName: 'eus'
  }
}

var shortLocation  = shortNames[location].shortName
var separated_prefix = '${appName}${separator}'
var separated_name = '[ResourceType]${separator}'
var separated_suffix = index == '' ? '${env}${separator}${shortLocation}' : '${env}${separator}${shortLocation}${padLeft(index,2,'0')}'

output resourceTemplate string = '${separated_prefix}${separated_name}${separated_suffix}'
output storageName string = take('${replace(toLower(replace('${separated_prefix}${separated_name}${separated_suffix}', '[ResourceType]', 'st')), '${separator}', '')}${uniqueString(subscription().subscriptionId)}', 24)
