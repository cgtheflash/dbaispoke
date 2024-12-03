// Parameters
@description('Environment name (e.g., prod, dev, qa)')
@allowed([
  'dev'
  'qa'
  'prod'
])
param environment string = 'dev'

@description('SQL Server administrator password')
@secure()
@minLength(12)
param sqlAdminPassword string

@description('App Service SKU')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param appServiceSku string = 'P1v2'

@description('Tags for all resources')
param tags object = {
  Environment: environment
  Project: 'DB Gameday'
  DeployedBy: 'Bicep'
}

param prefix string = 'dbgameday'
param vnetAddressPrefix string = '10.0.0.0/16'
param appgwSubnetPrefix string = '10.0.0.0/24'
param peSubnetPrefix string = '10.0.1.0/24'
param integrationSubnetPrefix string = '10.0.2.0/24'

// Add parameter for next hop IP
param defaultRouteNextHopIp string

// Add parameters
@description('Enable public network access for PaaS services')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

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
        name: 'allow-internet-to-appgw'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgs[0].outputs.asgId  // AppGW ASG
            }
          ]
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'allow-appgw-to-app'
        properties: {
          priority: 110
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
          priority: 120
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
          priority: 130
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
      {
        name: 'allow-azure-lb'
        properties: {
          priority: 4095
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'deny-all-inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
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
    subnets: subnets
    nsgIds: [
      nsg.outputs.nsgId
      nsg.outputs.nsgId
      nsg.outputs.nsgId
    ]
    routeTableId: routeTable.outputs.routeTableId
  }
  dependsOn: [
    nsg
    routeTable
  ]
}

// Create App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${prefix}-asp'
  location: resourceGroup().location
  tags: tags
  sku: {
    name: appServiceSku
    tier: 'PremiumV2'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Create App Service
module appService 'artifacts/appservice.bicep' = {
  name: 'appservice-deployment'
  params: {
    name: '${prefix}-app'
    location: resourceGroup().location
    tags: tags
    appServicePlanId: appServicePlan.id
    linuxFxVersion: 'dotnet:6'
    subnetId: vnet.outputs.subnetIds[2].id  // Use integration subnet (index 2)
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
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlAdminPassword
    skuName: 'Basic'
    tier: 'Basic'
    allowAzureIPs: false
    publicNetworkAccess: publicNetworkAccess
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
module appPrivateEndpoint 'artifacts/privateendpoint.bicep' = if (publicNetworkAccess == 'Disabled') {
  name: 'app-pe-deployment'
  params: {
    name: '${prefix}-app-pe'
    location: resourceGroup().location
    subnetId: vnet.outputs.subnetIds[1].id
    privateConnectResourceId: appService.outputs.appServiceId
    groupId: 'sites'
    asgIds: [asgs[1].outputs.asgId]
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
    subnetId: vnet.outputs.subnetIds[0].id
    skuName: 'Standard_v2'
    skuTier: 'Standard_v2'
    capacity: 2
    publicIpName: appGwPublicIp.outputs.publicIpId
    constructPublicFrontendIpConfig: true
    constructPrivateFrontendIpConfig: false
    backendPools: [
      {
        name: 'appServiceBackend'
        backendAddresses: [
          {
            fqdn: appService.outputs.appServiceName  
          }
        ]
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    httpSettings: [
      {
        name: 'appServiceHttpSetting'
        properties: {
          port: 443
          protocol: 'Https'
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
        frontendPort: 'port_443'
        protocol: 'Https'
        requireServerNameIndication: false
      }
    ]
    routingRules: [
      {
        name: 'appServiceRule'
        ruleType: 'Basic'
        httpListener: 'httpsListener'
        backendAddressPool: 'appServiceBackend'
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
