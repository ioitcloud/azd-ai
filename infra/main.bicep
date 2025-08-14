targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('The Azure region for all resources.')
param location string

@description('Name of the resource group to create or use')
param resourceGroupName string 

@description('Port exposed by the Tika container.')
param containerPort int = 9998

@description('Minimum replica count for Tika containers.')
param containerMinReplicaCount int = 2

@description('Maximum replica count for Tika containers.')
param containerMaxReplicaCount int = 3 

@description('Name of the PostgreSQL database.')
param databaseName string = 'litellmdb'

@description('Name of the PostgreSQL database admin user.')
param databaseAdminUser string = 'litellmuser'

@description('Password for the PostgreSQL database admin user.')
@secure()
param databaseAdminPassword string

param tikaContainerAppExists bool

/* @description('Master key for LiteLLM. Your master key for the proxy server.')
@secure()
param litellm_master_key string

@description('Salt key for LiteLLM. (CAN NOT CHANGE ONCE SET)')
@secure()
param litellm_salt_key string */

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  'azd-template': 'https://github.com/Build5Nines/azd-litellm'
}

var containerAppName = '${abbrs.appContainerApps}tika-${resourceToken}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module monitoring './shared/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}tika-${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}tika-${resourceToken}'
  }
  scope: rg
}  

/* module containerRegistry './shared/container-registry.bicep' = {
  name: 'cotainer-registry'
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
  scope: rg
}  */

module appsEnv './shared/apps-env.bicep' = {
  name: 'apps-env'
  params: {
    name: '${abbrs.appManagedEnvironments}tika-${resourceToken}'
    location: location
    tags: tags 
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
  scope: rg
} 

// Deploy PostgreSQL Server via module call.
module postgresql './shared/postgresql.bicep' = {
  name: 'postgresql'
  params: {
    name: '${abbrs.dBforPostgreSQLServers}litellm-${resourceToken}'
    location: location
    tags: tags
    databaseAdminUser: databaseAdminUser
    databaseAdminPassword: databaseAdminPassword
  }
  scope: rg
}

// Deploy PostgreSQL Database via module call.
module postgresqlDatabase './shared/postgresql_database.bicep' = {
  name: 'postgresqlDatabase'
  params: {
    serverName: postgresql.outputs.name
    databaseName: databaseName
  }
  scope: rg
}

// module keyvault './shared/keyvault.bicep' = {
//   name: 'keyvault'
//   params: {
//     name: '${abbrs.keyVaultVaults}litellm-${resourceToken}'
//     location: location
//     tags: tags
//   }
//   scope: rg
// }

// Deploy Tika Container App via module call.
module tika './app/tika.bicep' = {
  name: 'tika'
  params: {
    name: containerAppName
    containerAppsEnvironmentName: appsEnv.outputs.name
    // keyvaultName: keyvault.outputs.name

    tikaContainerAppExists: tikaContainerAppExists
    containerPort: containerPort
    containerMinReplicaCount: containerMinReplicaCount
    containerMaxReplicaCount: containerMaxReplicaCount
  }
  scope: rg
} 


/* output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output LITELLM_MASTER_KEY string = litellm_master_key
output LITELLM_SALT_KEY string = litellm_salt_key */

//output LITELLM_CONTAINER_APP_EXISTS bool = true
// output LITELLM_CONTAINERAPP_FQDN string = litellm.outputs.containerAppFQDN
// output POSTGRESQL_FQDN string = postgresql.outputs.fqdn


