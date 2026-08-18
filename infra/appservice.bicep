targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'
param vnetName string = 'vnet-secure-azure-web-dev'
param integrationSubnetName string = 'snet-appservice-integration-dev'

var suffix = uniqueString(resourceGroup().id)
var planName = 'asp-secure-azure-${environment}-${suffix}'
var frontendName = 'app-secure-frontend-${environment}-${suffix}'
var backendName = 'app-secure-backend-${environment}-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: integrationSubnetName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource frontend 'Microsoft.Web/sites@2023-12-01' = {
  name: frontendName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appCommandLine: 'npm start'
      alwaysOn: false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '20-lts'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

resource backend 'Microsoft.Web/sites@2023-12-01' = {
  name: backendName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appCommandLine: 'npm start'
      alwaysOn: false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '20-lts'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

resource frontendVnetConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: frontend
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: integrationSubnet.id
  }
}

resource backendVnetConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: backend
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: integrationSubnet.id
  }
}


output appServicePlanName string = appServicePlan.name
output frontendAppName string = frontend.name
output backendAppName string = backend.name
output frontendUrl string = 'https://${frontend.properties.defaultHostName}'
output backendUrl string = 'https://${backend.properties.defaultHostName}'
