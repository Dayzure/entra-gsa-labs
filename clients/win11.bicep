param location string = resourceGroup().location
param subnetResourceId string
param tags object
param adminUsername string
@secure()
param adminPassword string
param namePrefix string = 'gsalab'


var vmName = '${namePrefix}-win11'

module vmClient 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: vmName
  params: {
    name: vmName
    location: location
    vmSize: 'Standard_D4s_v3'
    imageReference: {
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-11'
      sku: 'win11-22h2-ent'
      version: 'latest'
    }
    osType: 'Windows'
    osDisk: {
      diskSizeGB: 128
      deleteOption: 'Delete' // delete the disk when the VM is deleted
      managedDisk: {
        storageAccountType: 'StandardSSD_LRS'
      }
      name: '${vmName}-os-disk'
    }
    zone: 0
    secureBootEnabled: true
    vTpmEnabled: true
    patchMode: 'ImageDefault'
    enableAutomaticUpdates: false
    enableHotpatching: false
    adminUsername: adminUsername
    adminPassword: adminPassword
    nicConfigurations: [
      {
        name: '${vmName}-nic'
        publicIPAddressVersion: 'IPv4'
        privateIPAddressVersion: 'IPv4'
        deleteOption: 'Delete'
        enableAcceleratedNetworking: false // not compatible with the SKU
        enableIPForwarding: false
        enableIPConfiguration: true
        enablePublicIPAddress: true
        ipConfigurations: [
          {
            name: '${vmName}-ipconfig-v4'
            publicIPAddressVersion: 'IPv4'
            privateIPAddressVersion: 'IPv4'
            subnetResourceId: subnetResourceId
            pipConfiguration: {
              publicIPAddressResourceId: vm_client_pip_v4.outputs.resourceId
            }
          }
        ]
      }
    ]
  }
}

module vm_client_pip_v4 'br/public:avm/res/network/public-ip-address:0.7.1' = {
  name: '${vmName}-pip-v4'
  params: {
    name: '${vmName}-pip-v4'
    dnsSettings: {
      domainNameLabel: '${namePrefix}w11'
      domainNameLabelScope: 'ResourceGroupReuse'
      fqdn: '${namePrefix}w11.${location}.cloudapp.azure.com'
    }
    location: location
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    tags: tags
  }
}
