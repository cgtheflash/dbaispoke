@description('Name of the Virtual WAN')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Flag to disable VPN encryption')
param disableVpnEncryption bool = false

@description('Allow branch-to-branch traffic within the Virtual WAN')
param allowBranchToBranchTraffic bool = true

@description('Allow VNet-to-VNet traffic within the Virtual WAN')
param allowVnetToVnetTraffic bool = true

@description('Type of Virtual WAN')
@allowed([
  'Basic'
  'Standard'
])
param type string = 'Standard'

resource virtualWan 'Microsoft.Network/virtualWans@2021-02-01' = {
  name: name
  location: location
  properties: {
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    allowVnetToVnetTraffic: allowVnetToVnetTraffic
    disableVpnEncryption: disableVpnEncryption
    type: type
  }
}
output virtualWanId string = virtualWan.id
