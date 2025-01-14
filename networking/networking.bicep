targetScope = 'resourceGroup'

@description('The name prefix for the resources.')
param namePrefix string

param location string
param tags object = {}

@description('The address prefixes for the virtual network. Add an IPV4 prefix.')
param addressPrefixServers array = ['10.100.0.0/24']
param addressPrefixClients array = ['10.200.0.0/24']
param addressPrefixHybridClients array = ['10.150.0.0/24']

var bastionSubnetAddressPrefixServers = cidrSubnet(addressPrefixServers[0], 26, 0) // the first /26 subnet in the address space
var addsSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 1) // the second /26 subnet in the address space
var serversSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 2) // the third /26 subnet in the address space
var bastionSubnetAddressPrefixClients = cidrSubnet(addressPrefixClients[0], 26, 0) // the first /26 subnet in the address space
var clientsSubnetAddressPrefixV4 = cidrSubnet(addressPrefixClients[0], 26, 1) // the second /26 subnet in the address space
var hybridClientSubnetPrefix = cidrSubnet(addressPrefixHybridClients[0], 25, 0)

module vnetServers 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetServers'
  params: {
    name: '${namePrefix}-vnetServers'
    location: location
    tags: tags
    addressPrefixes: addressPrefixServers
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [bastionSubnetAddressPrefixServers]
      }
      {
        name: 'adds-vms'
        addressPrefixes: [addsSubnetAddressPrefixV4]
      }
      {
        name: 'server-vms'
        addressPrefixes: [serversSubnetAddressPrefixV4]
      }
    ]
  }
}

module vnetClients 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetClients'
  params: {
    name: '${namePrefix}-vnetClients'
    location: location
    tags: tags
    addressPrefixes: addressPrefixClients
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [bastionSubnetAddressPrefixClients]
      }
      {
        name: 'client-vms'
        addressPrefixes: [clientsSubnetAddressPrefixV4]
      }
    ]
  }
}

module vnetHybridClients 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetHybridClients'
  params: {
    name: '${namePrefix}-vnetHybridClients'
    location: location
    tags: tags
    addressPrefixes: addressPrefixHybridClients
    dnsServers: [
      '10.100.0.68'
    ]
    subnets: [
      {
        name: 'hybrid-client-vms'
        addressPrefixes: [hybridClientSubnetPrefix]
      }
    ] 
  }
}

module vnetPeeringHybridClientsToServers 'vnetPeering.bicep' = {
  name: 'vnetPeeringHybridClientsToServers'
  params: {
    vnet1Name: vnetHybridClients.name
    vnet1Id: vnetHybridClients.outputs.resourceId
    vnet2Name: vnetServers.name
    vnet2Id: vnetServers.outputs.resourceId
  }
 }

module vnetPeeringServersToHybridClients 'vnetPeering.bicep' = {
  name: 'vnetPeeringServersToHybridClients'
  params: {
    vnet1Name: vnetServers.name
    vnet1Id: vnetServers.outputs.resourceId
    vnet2Name: vnetHybridClients.name
    vnet2Id: vnetHybridClients.outputs.resourceId
  }
  dependsOn: [
    vnetPeeringHybridClientsToServers
  ]
}

module bastionHosts 'bastionHosts.bicep' = {
  name: 'bastionHosts'
  params: {
    location: location
    tags: tags
    namePrefix: namePrefix
    vnetServersResourceId: vnetServers.outputs.resourceId
    vnetServersBastionSubnetResourceId: vnetServers.outputs.subnetResourceIds[0]
    vnetClientsResourceId: vnetClients.outputs.resourceId
    vnetClientsBastionSubnetResourceId: vnetClients.outputs.subnetResourceIds[0]
  }
  dependsOn: [
    vnetPeeringHybridClientsToServers
    vnetPeeringServersToHybridClients
  ]
}

@description('The resource ID of the adds subnet.')
output addsSubnetResourceId string = vnetServers.outputs.subnetResourceIds[1] // the second subnet is the vm subnet

@description('The resource ID of the servers subnet.')
output serversSubnetResourceId string = vnetServers.outputs.subnetResourceIds[2] // the second subnet is the vm subnet

@description('The resource ID of the virtual network.')
output vnetResourceId string = vnetServers.outputs.resourceId

@description('The resource ID of the virtual network for clients.')
output vnetClientsResourceId string = vnetClients.outputs.resourceId

@description('The resource ID of the virtual network for clients.')
output subnetClientsResourceId string = vnetClients.outputs.subnetResourceIds[1]

@description('The resource ID of the virtual network for hybrid clients.')
output vnetHybridClientsResourceId string = vnetHybridClients.outputs.resourceId

@description('The resource ID of the virtual network subnet for hybrid clients.')
output subnetHybridClientsResourceId string = vnetHybridClients.outputs.subnetResourceIds[0]
