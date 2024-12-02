@description('Name of the Virtual Hub')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Address prefix for the Virtual Hub')
param addressPrefix string = '10.0.0.0/24'

@description('ID of the Virtual WAN')
param virtualWanId string

resource virtualHub 'Microsoft.Network/virtualHubs@2021-02-01' = {
  name: name
  location: location
  properties: {
    virtualWan: {
      id: virtualWanId
    }
    addressPrefix: addressPrefix
  }
}

output virtualHubId string = virtualHub.id
