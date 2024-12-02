@description('Name of the Bastion Host')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Name of the Virtual Network to associate with the Bastion Host')
param virtualNetworkName string

@description('Public IP address for the Bastion Host')
param publicIpAddressId string

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${name}-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
  }
}

output bastionHostId string = bastionHost.id
