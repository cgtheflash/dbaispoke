@description('Name of the Virtual Network')
param name string

@description('Location for resources')
param location string

@description('Address prefix for the Virtual Network')
param addressPrefix string

@description('Subnets configuration')
param subnets array

@description('Network Security Group IDs')
param nsgIds array

@description('Tags for the resources')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsgIds[i]
        }
        privateEndpointNetworkPolicies: subnet.name == 'pe-subnet' ? 'Enabled' : 'Disabled'
      }
    }]
  }
}

output virtualNetworkId string = virtualNetwork.id

// Add output for subnet IDs
output subnetIds array = [for subnet in subnets: {
  name: subnet.name
  id: resourceId('Microsoft.Network/virtualNetworks/subnets', name, subnet.name)
}]
