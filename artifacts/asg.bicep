@description('Name of the Application Security Group')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: name
  location: location
}

output asgId string = applicationSecurityGroup.id
