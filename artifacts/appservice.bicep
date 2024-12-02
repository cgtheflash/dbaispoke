@description('Name of the App Service')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('App Service Plan ID')
param appServicePlanId string

@description('Runtime stack of the web app')
@allowed([
  'dotnet:6'
  'dotnet:7'
  'node:14-lts'
  'node:16-lts'
  'python:3.9'
  'python:3.10'
])
param linuxFxVersion string

@description('App settings for the web app')
param appSettings array = []

@description('Virtual Network subnet ID for integration')
param subnetId string = ''

@description('Tags for the resources')
param tags object = {}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: appSettings
      alwaysOn: true
    }
  }
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2022-03-01' = if (!empty(subnetId)) {
  parent: appService
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
    swiftSupported: true
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name 
