param vnet1Name string
param vnet1Id string
param vnet2Name string
param vnet2Id string

resource vnetPeering1To2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${vnet1Name}/to-${vnet2Name}'
  properties: {
    remoteVirtualNetwork: {
      id: vnet2Id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource vnetPeering2To1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${vnet2Name}/to-${vnet1Name}'
  properties: {
    remoteVirtualNetwork: {
      id: vnet1Id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
