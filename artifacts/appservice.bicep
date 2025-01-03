@description('Name of the App Service')
param name string

@description('Location for resources')
param location string

@description('Hosting Plan Name')
param hostingPlanName string

@description('Server Farm Resource Group')
param serverFarmResourceGroup string

@description('Subscription ID')
param subscriptionId string

@description('Always On setting')
param alwaysOn bool = true

@description('FTPS State')
@allowed(['FtpsOnly', 'Disabled'])
param ftpsState string = 'Disabled'

@description('Current Stack')
param currentStack string = 'dotnet'

@description('PHP Version')
param phpVersion string = 'OFF'

@description('.NET Framework Version')
@allowed([
  'v4.0'
  'v6.0'
  'v7.0'
  'v8.0'
  'v9.0'
])
param netFrameworkVersion string = 'v9.0'

@description('Tags for the resources')
param tags object = {}

@description('Enable public network access')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    siteConfig: {
      appSettings: []
      phpVersion: phpVersion
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      linuxFxVersion: currentStack
      windowsFxVersion: currentStack
    }
    serverFarmId: resourceId(subscriptionId, serverFarmResourceGroup, 'Microsoft.Web/serverfarms', hostingPlanName)
    clientAffinityEnabled: true
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
  }
}

resource scmCredentialPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: appService
  name: 'scm'
  properties: {
    allow: false
  }
}

resource ftpCredentialPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: appService
  name: 'ftp'
  properties: {
    allow: false
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name 
