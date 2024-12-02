@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Subnet resource ID for the NIC')
param subnetId string

@description('Private IP address for the NIC')
param ipAddress string

@description('Public IP resource ID for the NIC')
param publicIpId string

@description('NIC name')
param nicName string

@description('Array of Load Balancer Backend Pool IDs')
param lbBackendPoolIds array = []

@description('Array of Application Gateway Backend Pool IDs')
param appGwBackendPoolIds array = []

@description('Array of Application Security Group IDs')
param asgIds array = []


resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nicName
  location: location
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: ipAddress
          publicIPAddress: empty(publicIpId)
            ? null
            : {
                id: publicIpId
              }
          subnet: {
            id: subnetId
          }
          applicationGatewayBackendAddressPools: [
            for poolId in appGwBackendPoolIds: {
              id: poolId.id
            }
          ]
          loadBalancerBackendAddressPools: [
            for poolId in lbBackendPoolIds: {
              id: poolId.id
            }
          ]
          applicationSecurityGroups: [
            for asgId in asgIds: {
              id: asgId
            }
          ]
        }
      }
    ]
  }
}

output nicId string = nic.id
