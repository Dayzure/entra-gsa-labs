targetScope = 'subscription'

@description('Tags for the resources. Specify a value for `Environment` as `Production` or `Development` to configure the resource lock automatically.')
param tags object

@description('The CDX Tenant Domain - this will match the AD DS Domain name')
param adDomainName string

@description('Admin user name')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Azure region where all the resources shall be created. Pay attention to location availability of Azure Bastion: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table')
param resourceLocation string = 'westeurope'

@description('Azure resource group name to be created. All the resources will be placed in this resource group')
param resourceGroupName string = 'gsa-lab-rg'


// ------------------ Resource Groups -----------------

module rg_networking 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: '${uniqueString(deployment().name, resourceLocation)}-rg-networking'
  params: {
    name: resourceGroupName
    location: resourceLocation
    tags: tags
  }
}

// ------------------ Modules -----------------

module networking 'networking/networking.bicep' = {
  name: 'networking'
  scope: resourceGroup(resourceGroupName)
  params: {
    namePrefix: 'gsaLabs'
    location: resourceLocation
    tags: tags
  }
  dependsOn: [
    rg_networking
  ]
}

module vmadds 'servers/adds.bicep' = {
  name: 'ADDS'
  scope: resourceGroup(resourceGroupName)
  params: {
    adminUsername: adminUsername
    adDomainName: adDomainName
    subnetResourceId: networking.outputs.addsSubnetResourceId
    adminPassword: adminPassword
    tags: tags
  }
}

module updateDNS 'networking/updateDNS.bicep' = {
  name: 'updateDNSServer'
  scope: resourceGroup(resourceGroupName)
  params: {
    namePrefix: 'gsaLabs'
  }
  dependsOn: [
    vmadds
  ]
}

module vmSmbShareServer 'servers/smbShareServer.bicep' = {
  name: 'SMBShareServer'
  scope: resourceGroup(resourceGroupName)
  params: {
    adminUsername: adminUsername
    adDomainName: adDomainName
    //YsubnetResourceId: '/subscriptions/08edba72-f736-4467-9d35-7032f38ebce6/resourceGroups/gsaLabs/providers/Microsoft.Network/virtualNetworks/gsaLabs-vnetServers/subnets/server-vms'
    subnetResourceId: networking.outputs.serversSubnetResourceId
    adminPassword: adminPassword
    tags: tags
  }
  dependsOn: [
    updateDNS
  ]
}

module vmClient 'clients/win11.bicep' = {
  name: 'Win11ClientVM'
  scope: resourceGroup(resourceGroupName)
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetResourceId: networking.outputs.subnetClientsResourceId
    tags: tags
    location: resourceLocation
  }
}

module vmHybridClient 'clients/win11hybrid.bicep' = {
  name: 'Win11HybridClientVM'
  scope: resourceGroup(resourceGroupName)
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetResourceId: networking.outputs.subnetHybridClientsResourceId
    tags: tags
    location: resourceLocation
  }
  dependsOn:[
    updateDNS
  ]
}
