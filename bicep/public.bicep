param location string = 'West Europe'
param planName string = 'volunteeringtest'
param planSku string = 'P0v3'
param dataSiteName string = 'volunteeringtest'
param apiSiteName string = 'volunteeringapitest'
param apiStack string = 'DOTNETCORE|10.0'

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource dataSite 'Microsoft.Web/sites@2024-11-01' = {
  name: dataSiteName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'sitecontainers'
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource siteContainer 'Microsoft.Web/sites/sitecontainers@2024-11-01' = {
  parent: dataSite
  name: 'main'
  properties: {
    image: 'ghcr.io/volunteeringdata/data:latest'
    isMain: true
    startUpCommand: ''
    authType: 'Anonymous'
  }
}

resource apiSite 'Microsoft.Web/sites@2024-11-01' = {
  name: apiSiteName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: apiStack
      appSettings: [
        {
          name: 'QueryService__SparqlEndpointUri'
          value: 'https://volunteeringtest.azurewebsites.net/sparql'
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource apiSiteConfig 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: apiSite
  name: 'web'
  properties: {
    numberOfWorkers: 1
    linuxFxVersion: apiStack
    appCommandLine: 'dotnet Query.dll'
  }
}
