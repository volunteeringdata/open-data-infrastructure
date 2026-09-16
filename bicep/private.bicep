param location string = 'West Europe'
param planName string = 'volunteeringtest'
param planSku string = 'P0v3'
param dataSiteName string = 'volunteeringdatatest'
param apiSiteName string = 'volunteeringapitest'
param apiStack string = 'DOTNETCORE|10.0'
param vnetName string = 'volunteeringtest-vnet'
param subnetWebName string = 'web-subnet' 
param subnetPeName string = 'pe-subnet'

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
    publicNetworkAccess: 'Disabled'
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

resource dataSiteNetworkConfig 'Microsoft.Web/sites/networkConfig@2024-11-01' = {
  parent: dataSite
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetWebName)
    swiftSupported: true
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
          value: 'https://${apiSiteName}.azurewebsites.net/sparql'
        }
        {
          name: 'Proxy__Clusters__1__Destinations__1__Address'
         value: 'https://${dataSiteName}.azurewebsites.net/'
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    outboundVnetRouting: {
      allTraffic: false
      applicationTraffic: true
      backupRestoreTraffic: false
      contentShareTraffic: false
      imagePullTraffic: false
    }
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

resource apiSiteNetworkConfig 'Microsoft.Web/sites/networkConfig@2024-11-01' = {
  parent: apiSite
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetWebName)
    swiftSupported: true
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetPeName
        properties: {
          addressPrefix: '10.0.1.0/28'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnetWebName
        properties: {
          addressPrefix: '10.0.2.0/28'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource privateSiteDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource pprivateSiteDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateSiteDNSZone
  name: 'privatelink.azurewebsites.net-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource dataSitePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${dataSiteName}-pe'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${dataSiteName}-pls'
        properties: {
          privateLinkServiceId: dataSite.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource apiSitePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${apiSiteName}-pe'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: '${apiSiteName}-pls'
        properties: {
          privateLinkServiceId: apiSite.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource dataSitePrivateEndpointPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: dataSitePrivateEndpoint
  name: 'dataPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateSiteDNSZone.id
        }
      }
    ]
  }
}

resource apiSitePrivateEndpointPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: apiSitePrivateEndpoint
  name: 'apiPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateSiteDNSZone.id
        }
      }
    ]
  }
}
