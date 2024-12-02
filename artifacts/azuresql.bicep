@description('Name of the Azure SQL Server')
param serverName string

@description('Name of the Azure SQL Database')
param databaseName string

@description('Location for resources')
param location string

@description('Administrator username for the server')
param administratorLogin string

@description('Administrator password for the server')
@secure()
param administratorLoginPassword string

@description('Database SKU name')
param skuName string = 'Basic'

@description('Database tier')
param tier string = 'Basic'

@description('Allow Azure services to access server')
param allowAzureIPs bool = true

@description('Tags for the resources')
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: tier
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2021-11-01' = if (allowAzureIPs) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output serverName string = sqlServer.name
output databaseName string = sqlDatabase.name
output serverFqdn string = sqlServer.properties.fullyQualifiedDomainName 
