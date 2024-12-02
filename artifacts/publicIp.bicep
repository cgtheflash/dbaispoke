@description('Name of the Public IP')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Tags for the resources')
param tags object = {}

@description('Availability zones to use for the public IP. Use empty array for no zones.')
param zones array = []

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: !empty(zones) ? zones : null
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output publicIpId string = publicIp.id
