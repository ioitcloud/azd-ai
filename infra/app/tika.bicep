@description('Location for the resource.')
param location string = resourceGroup().location

@description('Tags for the resource.')
param tags object = {}

@description('Name of the Container Apps managed environment.')
param containerAppsEnvironmentName string

@description('Name for the App.')
param name string

@description('Port exposed by the Tika container.')
param containerPort int

@description('Minimum replica count for Tika containers.')
param containerMinReplicaCount int

@description('Maximum replica count for Tika containers.')
param containerMaxReplicaCount int

param tikaContainerAppExists bool

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: containerAppsEnvironmentName
}

module fetchLatestContainerImage '../shared/fetch-container-image.bicep' = {
  name: '${name}-fetch-image'
  params: {
    exists: tikaContainerAppExists
    containerAppName: name
  }
}

resource tikaContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'tika' })
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: containerPort
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'tika'
          image: 'apache/tika:latest-full'
          env: [] // No environment variables required for basic Tika setup
        }
      ]
      scale: {
        minReplicas: containerMinReplicaCount
        maxReplicas: containerMaxReplicaCount
      }
    }
  }
}

output containerAppName string = tikaContainerApp.name
output containerAppFQDN string = tikaContainerApp.properties.configuration.ingress.fqdn
