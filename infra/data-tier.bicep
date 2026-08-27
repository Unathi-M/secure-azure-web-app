targetScope = 'resourceGroup'

@description('Azure region for the data tier. Keep East US to match the existing VNet.')
param location string = resourceGroup().location

@description('Environment label used in resource names.')
param environment string = 'dev'

@description('Existing VNet created by infra/main.bicep.')
param vnetName string = 'vnet-secure-azure-web-dev'

@description('Existing subnet reserved for private endpoints.')
param privateEndpointSubnetName string = 'snet-private-endpoints-dev'

@description('Microsoft Entra object ID for the Azure SQL logical-server administrator.')
param sqlEntraAdminObjectId string

@description('Microsoft Entra user principal name for the Azure SQL logical-server administrator.')
param sqlEntraAdminLogin string

@description('Azure SQL Database SKU. Confirm regional availability before any future deployment.')
@allowed([
  'Basic'
  'S0'
])
param databaseSkuName string = 'Basic'

var suffix = toLower(take(uniqueString(resourceGroup().id), 10))
var sqlServerName = 'sql-secureazure-${environment}-${suffix}'
var sqlDatabaseName = 'sqldb-secure-azure-${environment}'
var privateEndpointName = 'pep-sql-secure-azure-${environment}'
var sqlServerDnsSuffix = az.environment().suffixes.sqlServerHostname
var privateDnsZoneName = 'privatelink.${sqlServerDnsSuffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: privateEndpointSubnetName
}

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' = {
  name: sqlServerName
  location: location
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: sqlEntraAdminLogin
      principalType: 'User'
      sid: sqlEntraAdminObjectId
      tenantId: tenant().tenantId
    }
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2025-01-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuName == 'Basic' ? 'Basic' : 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: databaseSkuName == 'Basic' ? 2147483648 : 10737418240
    zoneRedundant: false
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'sql-server-connection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource sqlPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: sqlPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql-database'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = '${sqlServer.name}.${sqlServerDnsSuffix}'
output sqlDatabaseName string = sqlDatabase.name
output privateEndpointName string = sqlPrivateEndpoint.name
output privateDnsZoneName string = privateDnsZone.name
