@description('Location for resources')
@allowed([
  'westus'
  'westus2'
  'centralus'
])
param location string

@description('VM name')
param vmName string

@description('Admin username for the VM')
param adminUser string

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('Image publisher')
param imagePublisher string

@description('Image offer')
param imageOffer string

@description('Image SKU')
param imageSku string

@description('Image SKU')
param imageVersion string

@description('VM size')
param vm_size string

@description('Diagnostics storage account name')
param diagStorageAccountName string

@description('Array of NIC IDs')
param nicIds array

@description('Availability set ID')
param availabilitySetId string = ''

@description('Availability zone for the VM. If empty, Availability Set will be used.')
param availabilityZone string = ''

var storageUrl = environment().suffixes.storage

resource pa_vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  zones: empty(availabilityZone) ? null : [
    availabilityZone
  ]
  plan: {
    name: imageSku
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${diagStorageAccountName}.blob.${storageUrl}'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: empty(imageVersion) ? 'latest' : imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        for nicId in nicIds: {
          id: nicId
          properties: {
            primary: nicId == nicIds[0] // Make the first NIC the primary one
          }
        }
      ]
    }
    availabilitySet: empty(availabilityZone) ? {
      id: availabilitySetId
    } : null
  }
}

output vmId string = pa_vm.id
