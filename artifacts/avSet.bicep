@description('Name of the Availability Set')
param name string

@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('Fault Domain Count')
@minValue(1)
@maxValue(3)
param faultDomainCount int = 2

@description('Update Domain Count')
@minValue(1)
@maxValue(20)
param updateDomainCount int = 5

resource availabilitySet 'Microsoft.Compute/availabilitySets@2021-03-01' = {
  name: name
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: faultDomainCount
    platformUpdateDomainCount: updateDomainCount
  }
}

output availabilitySetId string = availabilitySet.id
