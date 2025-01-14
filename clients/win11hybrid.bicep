param location string = resourceGroup().location
param subnetResourceId string
param tags object
param adminUsername string
@secure()
param adminPassword string
param namePrefix string = 'gsalab'


var vmName = '${namePrefix}-h-w11'

module vmClient 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: vmName
  params: {
    name: vmName
    location: location
    tags: tags
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
        enablePublicIPAddress: false
        ipConfigurations: [
          {
            name: '${vmName}-ipconfig-v4'
            privateIPAddressVersion: 'IPv4'
            subnetResourceId: subnetResourceId
          }
        ]
      }
    ]
  }
}
