@description('Name of the Virtual Network')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
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
      }
    }]
  }
}

output virtualNetworkId string = virtualNetwork.id
