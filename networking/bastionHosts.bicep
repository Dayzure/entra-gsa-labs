targetScope = 'resourceGroup'

@description('The name prefix for the resources.')
param namePrefix string

param location string
param tags object = {}

param vnetServersResourceId string
param vnetServersBastionSubnetResourceId string
param vnetClientsResourceId string
param vnetClientsBastionSubnetResourceId string

resource bastionServers_publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${namePrefix}-BastionServers-PublicIP'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
      id: vnetServersResourceId
    }
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetServersBastionSubnetResourceId
          }
          publicIPAddress: {
            id: bastionServers_publicIP.id
          }
        }
      }
    ]
  }
}

resource bastionClients_publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${namePrefix}-BastionClients-PublicIP'
  location: location
  tags: tags
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
      id: vnetClientsResourceId
    }
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetClientsBastionSubnetResourceId
          }
          publicIPAddress: {
            id: bastionClients_publicIP.id
          }
        }
      }
    ]
  }
}
