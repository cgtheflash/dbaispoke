@description('Name of the Route Table')
param name string

@description('Location for resources')
param location string

@description('Tags for the resources')
param tags object = {}

@description('Routes configuration')
param routes array

resource routeTable 'Microsoft.Network/routeTables@2020-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    routes: [for route in routes: {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefix
        nextHopType: route.nextHopType
        nextHopIpAddress: route.nextHopIpAddress
      }
    }]
  }
}

output routeTableId string = routeTable.id
