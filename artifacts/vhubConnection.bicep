@description('Name of the Virtual WAN Hub.')
param vWanHubName string

@description('Array of Virtual Network IDs to connect to the Virtual WAN Hub.')
param vNetsIDs array

@description('Flag to allow hub to remote VNet transit. Default is true.')
param allowHubToRemoteVnetTransit bool = true

@description('Flag to allow remote VNet to use hub VNet gateways. Default is true.')
param allowRemoteVnetToUseHubVnetGateways bool = true

@description('Flag to enable internet security. Default is true.')
param enableInternetSecurity bool = true

resource vWANHub 'Microsoft.Network/virtualHubs@2023-04-01' existing = {
  name: vWanHubName
}

// Loop through the vNetsIDs array to create connections for each spoke
resource hubConnections 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-04-01' = [for (vnetId, i) in vNetsIDs: {
  parent: vWANHub
  name: '${vWanHubName}-connection-${i}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetId
    }
    allowHubToRemoteVnetTransit: allowHubToRemoteVnetTransit
    allowRemoteVnetToUseHubVnetGateways: allowRemoteVnetToUseHubVnetGateways
    enableInternetSecurity: enableInternetSecurity
  }
}]
