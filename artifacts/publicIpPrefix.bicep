@description('Name of the Public IP Prefix')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('CIDR for the Public IP Prefix')
param cidr int

@description('Availability zones to use for the public IP. Use empty array for no zones.')
param zones array = []

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2020-11-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  zones: !empty(zones) ? zones : null
  properties: {
    prefixLength: cidr
  }
}

output publicIpPrefixId string = publicIpPrefix.id
