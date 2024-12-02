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

@description('The location for the deployment.')
param location string

@description('The user-assigned identity to use for executing the Azure CLI command.')
param userAssignedIdentityId string

resource AZCommandCreateHubConnection 'Microsoft.Resources/deploymentScripts@2020-10-01' = [for (vnetId, i) in vNetsIDs: {
  kind: 'AzureCLI'
  name: 'AZCommandCreateHubConnection-${i}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    azCliVersion: '2.52.0'
    arguments: '--vWanHubName ${vWanHubName} --vnetId ${vnetId} --allowHubToRemoteVnetTransit ${allowHubToRemoteVnetTransit ? 'true' : 'false'} --allowRemoteVnetToUseHubVnetGateways ${allowRemoteVnetToUseHubVnetGateways ? 'true' : 'false'} --enableInternetSecurity ${enableInternetSecurity ? 'true' : 'false'}'
    scriptContent: '''
      #!/bin/bash
      vWanHubName=$1
      vnetId=$2
      allowHubToRemoteVnetTransit=$3
      allowRemoteVnetToUseHubVnetGateways=$4
      enableInternetSecurity=$5

      az network vhub connection create \\
        --name ${vWanHubName}-connection-${i} \\
        --resource-group ${resourceGroup().name} \\
        --vhub-name $vWanHubName \\
        --remote-vnet $vnetId \\
        --allow-hub-to-remote-vnet-transit $allowHubToRemoteVnetTransit \\
        --allow-remote-vnet-to-use-hub-vnet-gateways $allowRemoteVnetToUseHubVnetGateways \\
        --enable-internet-security $enableInternetSecurity
    '''
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  }
}]
