@description('Name of the Load Balancer')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Array of Frontend IP Configurations')
param frontendIpConfigs array = []

@description('Array of Backend Pool Names')
param backendPoolNames array = []

@description('Array of Load Balancing Rules')
param loadBalancingRules array = []

@description('Array of Probes')
param probes array = []

@description('Array of Inbound NAT Pools')
param inboundNatPools array = []

@description('Array of Inbound NAT Rules')
param inboundNatRules array = []

@description('Array of Outbound Rules')
param outboundRules array = []

@description('SKU Name for the Load Balancer')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Standard'

@description('Is the Load Balancer Public?')
param isPublic bool = false

@description('Is the Load Balancer Regional or Global?')
@allowed([
  'Regional'
  'Global'
])
param scope string = 'Regional'

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: name
  location: location
  sku: {
    name: skuName
    tier: scope == 'Global' ? 'Global' : 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      for config in frontendIpConfigs: {
        name: config.name
        properties: {
          publicIPAddress: isPublic ? config.properties.publicIPAddress : null
          subnet: !isPublic ? config.properties.subnet : null
          privateIPAddress: !isPublic && config.properties.privateIPAllocationMethod != 'Dynamic' ? config.properties.privateIPAddress : null
          privateIPAllocationMethod: config.properties.privateIPAllocationMethod
          privateIPAddressVersion: !isPublic ? config.properties.privateIPAddressVersion : null
        }
      }
    ]
    backendAddressPools: [
      for pool in backendPoolNames: {
        name: pool.name
        properties: {}
      }
    ]
    loadBalancingRules: [
      for rule in loadBalancingRules: {
        name: rule.name
        properties: {
          frontendIPConfiguration: {
            id: rule.frontendIPConfiguration.id
          }
          backendAddressPool: {
            id: rule.backendAddressPool.id
          }
          probe: {
            id: rule.probe.id
          }
          protocol: rule.protocol
          loadDistribution: rule.loadDistribution
          frontendPort: rule.frontendPort
          backendPort: rule.backendPort
          idleTimeoutInMinutes: rule.idleTimeoutInMinutes
          enableFloatingIP: rule.enableFloatingIP
          disableOutboundSnat: rule.disableOutboundSnat
        }
      }
    ]
    probes: [
      for probe in probes: {
        name: probe.name
        properties: {
          protocol: probe.protocol
          port: probe.port
          intervalInSeconds: probe.intervalInSeconds
          numberOfProbes: probe.numberOfProbes
          requestPath: contains(['Http', 'Https'], probe.protocol) ? probe.requestPath : null
        }
      }
    ]
    inboundNatPools: [
      for natPool in inboundNatPools: {
        name: natPool.name
        properties: {
          backendPort: natPool.backendPort
          enableFloatingIP: natPool.enableFloatingIP
          enableTcpReset: natPool.enableTcpReset
          frontendIPConfiguration: {
            id: natPool.frontendIPConfigurationId
          }
          frontendPortRangeStart: natPool.frontendPortRangeStart
          frontendPortRangeEnd: natPool.frontendPortRangeEnd
          idleTimeoutInMinutes: natPool.idleTimeoutInMinutes
          protocol: natPool.protocol
        }
      }
    ]
    inboundNatRules: [
      for natRule in inboundNatRules: {
        name: natRule.name
        properties: {
          frontendIPConfiguration: {
            id: natRule.frontendIPConfiguration
          }
          backendPort: natRule.backendPort
          enableFloatingIP: natRule.enableFloatingIP
          enableTcpReset: natRule.enableTcpReset
          frontendPort: natRule.frontendPort
          idleTimeoutInMinutes: natRule.idleTimeoutInMinutes
          protocol: natRule.protocol
        }
      }
    ]
    outboundRules: [
      for rule in outboundRules: {
        name: rule.name
        properties: {
          allocatedOutboundPorts: rule.allocatedOutboundPorts
          backendAddressPool: {
            id: rule.backendAddressPool
          }
          enableTcpReset: rule.enableTcpReset
          frontendIPConfigurations: [
            {
              id: rule.frontendIPConfiguration
            }
          ]
          idleTimeoutInMinutes: rule.idleTimeoutInMinutes
          protocol: rule.protocol
        }
      }
    ]
  }
}

output loadBalancerId string = loadBalancer.id
