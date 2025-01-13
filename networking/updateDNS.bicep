targetScope = 'resourceGroup'

@description('The name prefix for the resources.')
param namePrefix string

@description('The address prefixes for the virtual network. Add an IPV4 prefix.')
param addressPrefixServers array = ['10.100.0.0/24']

var bastionSubnetAddressPrefixServers = cidrSubnet(addressPrefixServers[0], 26, 0) // the first /26 subnet in the address space
var addsSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 1) // the second /26 subnet in the address space
var serversSubnetAddressPrefixV4 = cidrSubnet(addressPrefixServers[0], 26, 2) // the third /26 subnet in the address space

module vnetServersDNS 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: '${namePrefix}-vnetServers'
  params: {
    name: '${namePrefix}-vnetServers'
    addressPrefixes: addressPrefixServers
    dnsServers: [
      '10.100.0.68'
    ]
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
