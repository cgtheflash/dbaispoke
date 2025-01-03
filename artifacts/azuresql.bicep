@description('Name of the Azure SQL Server')
param serverName string

@description('Name of the Azure SQL Database')
param databaseName string

@description('Location for resources')
param location string

// @description('Administrator username for the server')
// param administratorLogin string

// @description('Administrator password for the server')
// @secure()
// param administratorLoginPassword string

@description('Database SKU name')
param skuName string = 'Basic'

@description('Database tier')
param tier string = 'Basic'

@description('Allow Azure services to access server')
param allowAzureIPs bool = true

@description('Tags for the resources')
param tags object = {}

@description('Enable public network access')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

@description('Object ID of the Azure Entra group for SQL administrators')
param sqlAdminGroupObjectId string

@description('Display name of the Azure Entra group for SQL administrators')
param sqlAdminGroupName string = 'SQL Administrators'

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    // administratorLogin: administratorLogin
    // administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    publicNetworkAccess: publicNetworkAccess
    minimalTlsVersion: '1.2'
    restrictOutboundNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: sqlAdminGroupName
      sid: sqlAdminGroupObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
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

output serverId string = sqlServer.id
output serverName string = sqlServer.name
output databaseName string = sqlDatabase.name
output serverFqdn string = sqlServer.properties.fullyQualifiedDomainName 
