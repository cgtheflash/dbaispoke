@description('Name of the Network Security Group')
param name string

@description('Location for resources')
param location string

@description('Security rules for the NSG')
param rules array

@description('Tags for the resources')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: rules
  }
}

output nsgId string = networkSecurityGroup.id
