@description('Name of the Private Endpoint')
param name string

@description('Location for resources')
param location string

@description('Resource ID of the subnet where the private endpoint will be created')
param subnetId string

@description('Resource ID of the resource to connect to')
param privateConnectResourceId string

@description('Group ID of the private link service')
@allowed([
  'sites'           // App Service
  'sites-staging'   // App Service slots
  'sqlServer'       // Azure SQL
  'blob'            // Storage Account blob
  'file'            // Storage Account file
  'queue'          // Storage Account queue
  'table'          // Storage Account table
  'registry'       // Container Registry
  'vault'          // Key Vault
])
param groupId string

@description('Array of private DNS zone resource IDs')
param privateDnsZoneIds array = []

@description('Application Security Group IDs to associate with the private endpoint')
param asgIds array = []

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: privateConnectResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
    applicationSecurityGroups: [for asgId in asgIds: {
      id: asgId
    }]
  }
}

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = if (!empty(privateDnsZoneIds)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [for (zoneId, i) in privateDnsZoneIds: {
      name: 'config${i + 1}'
      properties: {
        privateDnsZoneId: zoneId
      }
    }]
  }
}

output privateEndpointId string = privateEndpoint.id
output privateEndpointIp string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
