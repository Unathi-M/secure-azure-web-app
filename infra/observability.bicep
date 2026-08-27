targetScope = 'resourceGroup'

@description('Azure region for monitoring resources. Keep East US to match the existing project resources.')
param location string = resourceGroup().location

@description('Environment label used in resource names.')
param environment string = 'dev'

@minValue(30)
@maxValue(730)
@description('Log Analytics retention in days.')
param logRetentionInDays int = 30

var suffix = toLower(take(uniqueString(resourceGroup().id), 10))
var workspaceName = 'log-secure-azure-${environment}-${suffix}'
var applicationInsightsName = 'appi-secure-azure-${environment}-${suffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableIpMasking: false
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output applicationInsightsName string = applicationInsights.name
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
