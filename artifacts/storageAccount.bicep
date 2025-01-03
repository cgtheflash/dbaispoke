@description('Name of the Storage Account')
param name string

@description('Location for resources')
param location string

@description('SKU for the Storage Account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param skuName string

@description('Kind of the Storage Account')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string

@description('Access tier for the Storage Account')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Enable blob public access')
param enableBlobPublicAccess bool = true

@description('Enable public network access')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

@description('Tags for the resources')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: enableBlobPublicAccess
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
      bypass: 'None'
    }
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    allowedCopyScope: 'AAD'
    encryption: {
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
