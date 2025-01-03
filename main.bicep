// Parameters
@description('Environment name (e.g., prod, dev, qa)')
@allowed([
  'dev'
  'qa'
  'prod'
])
param environment string = 'prod'

// @description('SQL Server administrator password')
// @secure()
// @minLength(12)
// param sqlAdminPassword string

@description('App Service SKU')
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
param appServiceSku string = 'P1'

@description('The runtime stack of the app')
@allowed([
  '.net'
  'php'
  'node'
  'html'
])
param language string = '.net'

@description('Tags for all resources')
param tags object = {
  Environment: environment
  Project: 'DB Gameday'
  DeployedBy: 'Bicep'
}

param prefix string = 'dbgameday'
param vnetAddressPrefix string = '10.123.4.0/23'
param appgwSubnetPrefix string = '10.123.4.0/24'
param peSubnetPrefix string = '10.123.5.0/25'
param integrationSubnetPrefix string = '10.123.5.128/25'

// Add parameter for next hop IP
param defaultRouteNextHopIp string = '10.123.0.4'

// Add parameters
@description('Enable public network access for PaaS services')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

@description('Object ID of the Azure Entra group for SQL administrators')
param sqlAdminGroupObjectId string

@description('Display name of the Azure Entra group for SQL administrators')
param sqlAdminGroupName string = 'Gameday SQL Administrators'

// Add these parameters near the other app service related parameters
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

// Network configuration
var vnetName = '${prefix}-vnet'
var subnets = [
  {
    name: 'appgw-subnet'
    addressPrefix: appgwSubnetPrefix
    delegations: []
  }
  {
    name: 'pe-subnet'
    addressPrefix: peSubnetPrefix
    delegations: []
  }
  {
    name: 'integration-subnet'
    addressPrefix: integrationSubnetPrefix
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
]

// ASG configuration
var asgNames = [
  '${prefix}-appgw-asg'
  '${prefix}-app-asg'
  '${prefix}-storage-asg'
]

// Create ASGs
module asgs 'artifacts/asg.bicep' = [for asgName in asgNames: {
  name: 'asg-${asgName}'
  params: {
    name: asgName
    location: resourceGroup().location
  }
}]

// Create NSG with zero trust rules using ASGs
module nsg 'artifacts/nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    name: '${prefix}-nsg'
    location: resourceGroup().location
    tags: tags
    rules: [
      {
        name: 'allow-gwm'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-internet-to-appgw'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: appgwSubnetPrefix
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'allow-appgw-to-app'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceApplicationSecurityGroups: [
            {
              id: asgs[0].outputs.asgId  // AppGW ASG
            }
          ]
          destinationApplicationSecurityGroups: [
            {
              id: asgs[1].outputs.asgId  // App ASG
            }
          ]
          destinationPortRange: '443'
        }
      }
      {
        name: 'allow-app-to-sql'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceApplicationSecurityGroups: [
            {
              id: asgs[1].outputs.asgId  // App ASG
            }
          ]
          destinationPortRange: '1433'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'allow-vnet-to-storage'
        properties: {
          priority: 140
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgs[2].outputs.asgId  // Storage ASG
            }
          ]
          destinationPortRange: '443'
        }
      }
      // {
      //   name: 'allow-azureLoadBalancer'
      //   properties: {
      //     protocol: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     sourceAddressPrefix: 'AzureLoadBalancer'
      //     destinationAddressPrefix: '*'
      //     access: 'Allow'
      //     priority: 4095
      //     direction: 'Inbound'
      //   }
      // }
      // {
      //   name: 'deny-all-inbound'
      //   properties: {
      //     priority: 4096
      //     direction: 'Inbound'
      //     access: 'Deny'
      //     protocol: '*'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '*'
      //   }
      // }
    ]
  }
  dependsOn: [
    asgs
  ]
}

// Create Route Table with default route
module routeTable 'artifacts/rt.bicep' = {
  name: 'rt-deployment'
  params: {
    name: '${prefix}-rt'
    location: resourceGroup().location
    tags: tags
    routes: [
      {
        name: 'default-route'
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: defaultRouteNextHopIp
      }
    ]
  }
}

// Create VNET with subnets
module vnet 'artifacts/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    name: vnetName
    location: resourceGroup().location
    tags: tags
    addressPrefix: vnetAddressPrefix
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      addressPrefix: subnet.addressPrefix
      delegations: subnet.delegations
      routeTableId: subnet.name == 'appgw-subnet' ? null : routeTable.outputs.routeTableId
    }]
    nsgIds: [
      nsg.outputs.nsgId
      nsg.outputs.nsgId
      nsg.outputs.nsgId
    ]
  }
  dependsOn: [
    nsg
    routeTable
  ]
}

// Create App Service
module appService 'artifacts/appservice.bicep' = {
  name: 'appservice-deployment'
  params: {
    name: '${prefix}-app'
    location: resourceGroup().location
    tags: tags
    sku: appServiceSku
    language: language
    netFrameworkVersion: netFrameworkVersion
    windowsDotnetVersion: windowsDotnetVersion
    subnetId: vnet.outputs.subnetIds[2].id  // Integration subnet (index 2)
    publicNetworkAccess: publicNetworkAccess
  }
  dependsOn: [
    vnet
  ]
}

// Create Azure SQL Server and Database
module sqlServer 'artifacts/azuresql.bicep' = {
  name: 'sql-deployment'
  params: {
    serverName: '${prefix}-sql'
    databaseName: '${prefix}-db'
    location: resourceGroup().location
    tags: tags
    // administratorLogin: 'sqladmin'
    // administratorLoginPassword: sqlAdminPassword
    skuName: 'Basic'
    tier: 'Basic'
    allowAzureIPs: false
    publicNetworkAccess: publicNetworkAccess
    sqlAdminGroupObjectId: sqlAdminGroupObjectId
    sqlAdminGroupName: sqlAdminGroupName
  }
  dependsOn: [
    vnet
  ]
}

// Create Private Endpoint for SQL Server
module sqlPrivateEndpoint 'artifacts/privateendpoint.bicep' = if (publicNetworkAccess == 'Disabled') {
  name: 'sql-pe-deployment'
  params: {
    name: '${prefix}-sql-pe'
    location: resourceGroup().location
    subnetId: vnet.outputs.subnetIds[1].id  // Use PE subnet (index 1)
    privateConnectResourceId: sqlServer.outputs.serverId
    groupId: 'sqlServer'
    asgIds: [asgs[1].outputs.asgId]
  }
  dependsOn: [
    sqlServer
    vnet
  ]
}

// Create Private Endpoint for App Service
module appPrivateEndpoint 'artifacts/privateendpoint.bicep' = {
  name: 'app-pe-deployment'
  params: {
    name: '${prefix}-app-pe'
    location: resourceGroup().location
    subnetId: vnet.outputs.subnetIds[1].id  // PE subnet (index 1)
    privateConnectResourceId: appService.outputs.appServiceId
    groupId: 'sites'
    asgIds: [asgs[1].outputs.asgId]  // App ASG
  }
  dependsOn: [
    appService
    vnet
  ]
}

// Create Public IP for Application Gateway
module appGwPublicIp 'artifacts/publicIp.bicep' = {
  name: 'appgw-pip-deployment'
  params: {
    name: '${prefix}-appgw-pip'
    location: resourceGroup().location
    tags: tags
  }
}

// Create Application Gateway
module appGw 'artifacts/appgw.bicep' = {
  name: 'appgw-deployment'
  params: {
    appgwName: '${prefix}-appgw'
    location: resourceGroup().location
    tags: tags
    subnetId: vnet.outputs.subnetIds[0].id
    publicIpName: appGwPublicIp.name
    backendPools: [
      {
        name: 'app-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: '${appService.outputs.appServiceName}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    skuName: 'Standard_v2'
    skuTier: 'Standard_v2'
    capacity: 2
    constructPublicFrontendIpConfig: true
    constructPrivateFrontendIpConfig: false
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    httpSettings: [
      {
        name: 'appServiceHttpSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    listeners: [
      {
        name: 'httpsListener'
        frontendIPConfiguration: 'appGwPublicFrontendIp'
        frontendPort: 'port_80'
        protocol: 'Http'
        requireServerNameIndication: false
      }
    ]
    routingRules: [
      {
        name: 'appServiceRule'
        ruleType: 'Basic'
        httpListener: 'httpsListener'
        backendAddressPool: 'app-backend'
        backendHttpSettings: 'appServiceHttpSetting'
        priority: 100
      }
    ]
  }
  dependsOn: [
    appGwPublicIp
    appService
    vnet
  ]
}

module sqlBackupStorage 'artifacts/storageAccount.bicep' = {
  name: 'sql-backup-storage-deployment'
  params: {
    name: '${prefix}sqlbackups${environment}'
    location: resourceGroup().location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    enableBlobPublicAccess: false
    publicNetworkAccess: publicNetworkAccess
  }
}

module sqlBackupStoragePe 'artifacts/privateendpoint.bicep' = {
  name: 'sql-backup-pe-deployment'
  params: {
    name: '${prefix}-sqlbackup-pe'
    location: resourceGroup().location
    subnetId: '${vnet.outputs.virtualNetworkId}/subnets/${subnets[1].name}'
    privateConnectResourceId: sqlBackupStorage.outputs.storageAccountId
    groupId: 'blob'
    asgIds: [asgs[2].outputs.asgId]
  }
  dependsOn: [
    sqlBackupStorage
    vnet
  ]
}

output vnetId string = vnet.outputs.virtualNetworkId
output appServiceUrl string = appService.outputs.appServiceName
output sqlServerFqdn string = sqlServer.outputs.serverFqdn
