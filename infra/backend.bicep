targetScope = 'resourceGroup'

@description('Azure region for backend resources. Keep East US to match the existing VNet.')
param location string = resourceGroup().location

@description('Environment label used in resource names.')
param environment string = 'dev'

@description('Existing VNet created by infra/main.bicep.')
param vnetName string = 'vnet-secure-azure-web-dev'

@description('Existing dedicated subnet delegated to Microsoft.Web/serverfarms.')
param integrationSubnetName string = 'snet-appservice-integration-dev'

@description('The deployed Static Web Apps origin permitted to call the backend API.')
param allowedFrontendOrigin string = 'https://thankful-dune-09f3e2d0f.7.azurestaticapps.net'

@secure()
@description('Optional Application Insights connection string. Leave empty until an observability resource exists.')
param applicationInsightsConnectionString string = ''

@description('Dedicated App Service SKU. B1 is the initial target; do not change it until quota availability is checked.')
@allowed([
  'B1'
  'S1'
])
param appServicePlanSku string = 'B1'

var suffix = toLower(take(uniqueString(resourceGroup().id), 10))
var appServicePlanName = 'asp-secure-azure-api-${environment}-${suffix}'
var backendName = 'app-secure-backend-${environment}-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: integrationSubnetName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
    tier: appServicePlanSku == 'B1' ? 'Basic' : 'Standard'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource backend 'Microsoft.Web/sites@2023-12-01' = {
  name: backendName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: integrationSubnet.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appCommandLine: 'npm start'
      alwaysOn: false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '20-lts'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ALLOWED_ORIGINS'
          value: allowedFrontendOrigin
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
      ]
    }
  }
}


output appServicePlanName string = appServicePlan.name
output backendAppName string = backend.name
output backendUrl string = 'https://${backend.properties.defaultHostName}'
output backendPrincipalId string = backend.identity.principalId
