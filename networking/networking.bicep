targetScope = 'resourceGroup'

@description('The name prefix for the resources.')
param namePrefix string

param location string
param tags object = {}

@description('The address prefixes for the virtual network. Add an IPV4 prefix.')
param addressPrefixServers array = ['10.100.0.0/24']
param addressPrefixClients array = ['10.200.0.0/24']

var bastionSubnetAddressPrefixServers = cidrSubnet(addressPrefixServers[0], 26, 0) // the first /26 subnet in the address space
var addsSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 1) // the second /26 subnet in the address space
var serversSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 2) // the third /26 subnet in the address space
var bastionSubnetAddressPrefixClients = cidrSubnet(addressPrefixClients[0], 26, 0) // the first /26 subnet in the address space
var clientsSubnetAddressPrefixV4 = cidrSubnet(addressPrefixClients[0], 26, 1) // the second /26 subnet in the address space

module vnetServers 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetServers'
  params: {
    name: '${namePrefix}-vnetServers'
    location: location
    addressPrefixes: addressPrefixServers
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [bastionSubnetAddressPrefixServers]
        networkSecurityGroupResourceId: nsg_bastion.outputs.resourceId
      }
      {
        name: 'adds-vms'
        addressPrefixes: [addsSubnetAddressPrefixV4]
        networkSecurityGroupResourceId: nsg_server_vms.outputs.resourceId
      }
      {
        name: 'server-vms'
        addressPrefixes: [serversSubnetAddressPrefixV4]
        networkSecurityGroupResourceId: nsg_server_vms.outputs.resourceId
      }
    ]
  }
}

module vnetClients 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetClients'
  params: {
    name: '${namePrefix}-vnetClients'
    location: location
    addressPrefixes: addressPrefixClients
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [bastionSubnetAddressPrefixClients]
        networkSecurityGroupResourceId: nsg_bastion.outputs.resourceId
      }
      {
        name: 'client-vms'
        addressPrefixes: [clientsSubnetAddressPrefixV4]
        networkSecurityGroupResourceId: nsg_client_vms.outputs.resourceId
      }
    ]
  }
}

module nsg_bastion 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: '${namePrefix}-nsg-bastion'
  params: {
    name: 'NSG-Bastion'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          priority: 150
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowSshOutbound'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowHttpOutbound'
        properties: {
          priority: 130
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

module nsg_server_vms 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: '${namePrefix}-nsg-server'
  params: {
    name: 'NSG-Server-VMs'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'virtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'virtualNetwork'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

module nsg_client_vms 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: '${namePrefix}-nsg-client'
  params: {
    name: 'NSG-Client-VMs'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'virtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'virtualNetwork'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource azureBastionServers 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: '${namePrefix}-BastionServers'
  location: location // pay attention to product availability: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table !!
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    virtualNetwork: {
      id: vnetServers.outputs.resourceId
    }
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetServers.outputs.subnetResourceIds[0]
          }
          publicIPAddress: {
            id: bastionServers_publicIP.id
          }
        }
      }
    ]
  }
}

resource bastionServers_publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${namePrefix}-BastionServers-PublicIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource azureBastionClients 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: '${namePrefix}-BastionClients'
  location: location // pay attention to product location availability: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    virtualNetwork: {
      id: vnetClients.outputs.resourceId
    }
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetClients.outputs.subnetResourceIds[0]
          }
          publicIPAddress: {
            id: bastionClients_publicIP.id
          }
        }
      }
    ]
  }
}

resource bastionClients_publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${namePrefix}-BastionClients-PublicIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
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
