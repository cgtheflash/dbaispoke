@description('Web app name')
@minLength(2)
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param sku string = 'P1'

@description('The runtime stack of the app')
@allowed([
  '.net'
  'php'
  'node'
  'html'
])
param language string = '.net'

@description('Runtime stack of the web app')
@allowed([
  'v4.0'
  'v6.0'
  'v7.0'
  'v8.0'
  'v9.0'
])
param netFrameworkVersion string = 'v9.0'

@description('Windows .NET runtime version')
@allowed([
  'DOTNET|6.0'
  'DOTNET|7.0'
  'DOTNET|8.0'
  'DOTNET|9.0-STS'
])
param windowsDotnetVersion string = 'DOTNET|9.0-STS'

@description('Tags for the resources')
param tags object = {}

var appServicePlanName = 'AppServicePlan-${name}'
var configReference = {
  '.net': {
    comments: '.Net app. No additional configuration needed.'
    netFrameworkVersion: netFrameworkVersion
    windowsFxVersion: windowsDotnetVersion
  }
  html: {
    comments: 'HTML app. No additional configuration needed.'
  }
  php: {
    phpVersion: '7.4'
  }
  node: {
    appSettings: [
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '12.15.0'
      }
    ]
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: union(configReference[language], {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      alwaysOn: true
      http20Enabled: true
      use32BitWorkerProcess: false
    })
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

output appServiceId string = webApp.id
output appServiceName string = webApp.name
output appServicePlanId string = appServicePlan.id 
