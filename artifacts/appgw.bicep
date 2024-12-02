@description('Application Gateway name.')
param appgwName string = ''

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('ID of the subnet for the Application Gateway')
param subnetId string

@description('SKU Name for the Application Gateway')
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param skuName string = 'Standard_v2'

@description('SKU Tier for the Application Gateway')
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param skuTier string = 'Standard_v2'

@description('Capacity for the Application Gateway')
param capacity int = 2

@description('Array of HTTP Settings for Application Gateway')
param httpSettings array = []

@description('Array of Listeners for Application Gateway')
param listeners array = []

@description('Array of Routing Rules for Application Gateway')
param routingRules array = []

@description('Array of Probes for Application Gateway')
param probes array = []

@description('Array of Frontend Ports for Application Gateway')
param frontendPorts array = []

@description('Boolean indicating whether to construct a public frontend IP configuration')
param constructPublicFrontendIpConfig bool

@description('Boolean indicating whether to construct a private frontend IP configuration')
param constructPrivateFrontendIpConfig bool

@description('Public IP name for Application Gateway')
param publicIpName string

@description('Array of Backend Pools for Application Gateway')
param backendPools array = []

@description('Tags for the resources')
param tags object = {}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-11-01' = if (constructPublicFrontendIpConfig || constructPrivateFrontendIpConfig) {
  name: appgwName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
      tier: skuTier
      capacity: capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: concat(
      (constructPublicFrontendIpConfig
        ? [
            {
              name: 'appGwPublicFrontendIp'
              properties: {
                publicIPAddress: {
                  id: resourceId('Microsoft.Network/publicIPAddresses', publicIpName)
                }
              }
            }
          ]
        : []),
      (constructPrivateFrontendIpConfig
        ? [
            {
              name: 'appGwPrivateFrontendIp'
              properties: {
                privateIPAllocationMethod: 'Dynamic'
                subnet: {
                  id: subnetId
                }
              }
            }
          ]
        : [])
    )
    frontendPorts: frontendPorts
    backendAddressPools: [
      for backendPool in backendPools: {
        name: backendPool.name
        properties: {}
      }
    ]
    backendHttpSettingsCollection: httpSettings
    httpListeners: [
      for listener in listeners: {
        name: listener.name
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appgwName,
              listener.frontendIPConfiguration
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwName, listener.frontendPort)
          }
          protocol: listener.protocol
          hostName: listener.hostName
          requireServerNameIndication: listener.requireServerNameIndication
        }
      }
    ]
    requestRoutingRules: [
      for rule in routingRules: {
        name: rule.name
        properties: {
          ruleType: rule.ruleType
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgwName, rule.httpListener)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgwName, rule.backendAddressPool)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgwName, rule.backendHttpSettings)
          }
          priority: rule.priority
        }
      }
    ]
    probes: probes
    enableHttp2: false
  }
}

output applicationGatewayId string = applicationGateway.id
