@description('Name of the NAT Gateway')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Public IP addresses for the NAT Gateway')
param publicIpAddresses array

@description('Public IP prefixes for the NAT Gateway')
param publicIpPrefixes array

@description('Availability Zones for the NAT Gateway')
param zones array = []

resource natGateway 'Microsoft.Network/natGateways@2021-02-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  zones: !empty(zones) ? zones : null
  properties: {
    publicIpAddresses: [for ip in publicIpAddresses: {
      id: ip
    }]
    publicIpPrefixes: [for prefix in publicIpPrefixes: {
      id: prefix
    }]
    idleTimeoutInMinutes: 4
  }
}

output natGatewayId string = natGateway.id
