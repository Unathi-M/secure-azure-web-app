targetScope = 'resourceGroup'

@description('Azure region for the deployment')
param location string = resourceGroup().location

@description('Environment name used in resource names')
param environment string = 'dev'

@description('Virtual network address space')
param vnetAddressPrefix string = '10.20.0.0/16'

@description('Integration subnet address space for App Service VNet integration')
param integrationSubnetPrefix string = '10.20.1.0/24'

@description('Private endpoint subnet address space')
param privateEndpointSubnetPrefix string = '10.20.2.0/24'

@description('Reserved test or management subnet address space')
param testSubnetPrefix string = '10.20.3.0/24'

var vnetName = 'vnet-secure-azure-web-${environment}'
var integrationNsgName = 'nsg-secure-azure-integration-${environment}'
var privateEndpointNsgName = 'nsg-secure-azure-private-endpoints-${environment}'

resource integrationNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: integrationNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyUnnecessaryOutboundInternet'
        properties: {
          priority: 4096
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          description: 'Deny direct internet egress from the integration subnet by default.'
        }
      }
    ]
  }
}

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: privateEndpointNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          description: 'Allow private traffic within the project VNet.'
        }
      }
      {
        name: 'DenyUnnecessaryInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny other inbound traffic to the private endpoint subnet.'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-appservice-integration-${environment}'
        properties: {
          addressPrefix: integrationSubnetPrefix
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: integrationNsg.id
          }
        }
      }
      {
        name: 'snet-private-endpoints-${environment}'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: privateEndpointNsg.id
          }
        }
      }
      {
        name: 'snet-test-management-${environment}'
        properties: {
          addressPrefix: testSubnetPrefix
        }
      }
    ]
  }
}

output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
output integrationSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-appservice-integration-${environment}')
output privateEndpointSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-private-endpoints-${environment}')
