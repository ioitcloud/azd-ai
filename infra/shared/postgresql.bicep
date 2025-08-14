@description('The location of the PostgreSQL server.')
param location string

@description('The name of the PostgreSQL server.')
param name string

@description('The SKU name for the PostgreSQL server.')
param skuName string = 'Standard_D2ds_v4'

@description('The tier for the PostgreSQL server.')
@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
  'Burstable'
])
param skuTier string = 'GeneralPurpose'

@description('The version of the PostgreSQL server.')
param version string = '16'

@description('Azure database for PostgreSQL storage Size ')
param storageSizeGB int = 32

@description('PostgreSQL Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

@description('The tags to apply to the resources.')
param tags object = {}

@description('The subnet ID for the PostgreSQL server.')
param subnetId string = ''

@description('Name for DNS Private Zone when connecting to Subnet')
param dnsZoneName string = name

@description('Fully Qualified DNS Private Zone')
param dnsZoneFqdn string = '${dnsZoneName}.postgres.database.azure.com'

@description('The database admin user for the PostgreSQL server.')
param databaseAdminUser string

@secure()
@description('The database admin password for the PostgreSQL server.')
param databaseAdminPassword string

@description('High Availability Mode')
@allowed([
  'ZoneRedundant'
  'Disabled'
])
param highAvailabilityMode string = 'Disabled'


var connectSubnet = !empty(subnetId)

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (connectSubnet) {
  name: dnsZoneFqdn
  location: 'global'
}

resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-11-01-preview' = {
  name: name
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: databaseAdminUser
    administratorLoginPassword: databaseAdminPassword
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
      tenantId: subscription().tenantId
    }
    storage: {
      storageSizeGB: storageSizeGB  
    }
    createMode: 'Default'
    version: version
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: highAvailabilityMode
    }
    network: connectSubnet ?{
      delegatedSubnetResourceId: subnetId
      privateDnsZoneArmResourceId: dnszone.id
      publicNetworkAccess: 'Enabled'
    } : {
      publicNetworkAccess: 'Enabled'
    }
  }
  tags: tags
}

resource firewallRuleAllowAzureIPs 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-11-01-preview' = {
  parent: postgresqlServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output name string = postgresqlServer.name
output fqdn string = postgresqlServer.properties.fullyQualifiedDomainName
