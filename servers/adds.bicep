param location string = resourceGroup().location
param adDomainName string
param subnetResourceId string
param tags object
param adminUsername string
@secure()
param adminPassword string
param namePrefix string = 'gsalab'
param vmSize string


var vmName = '${namePrefix}-adds'

module vm 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: vmName
  params: {
    name: vmName
    location: location
    vmSize: vmSize
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2022-datacenter'
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
    dataDisks: [
        {
          name: '${vmName}-data-disk'
          caching: 'ReadWrite'
          createOption: 'Empty'
          diskSizeGB: 20
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          lun: 0
        }
      ]
    zone: 0
    secureBootEnabled: true
    vTpmEnabled: true
    patchMode: 'AutomaticByPlatform'
    enableAutomaticUpdates: true
    enableHotpatching: false
    maintenanceConfigurationResourceId: maintenanceConfiguration.id
    adminUsername: adminUsername
    adminPassword: adminPassword
    disablePasswordAuthentication: false
    // managedIdentities: { systemAssigned: true }
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
    extensionDSCConfig: {
      enabled: true
      settings: {
        ModulesUrl: 'https://github.com/Dayzure/entra-gsa-labs/raw/refs/heads/main/dsc/CreateADPDC.zip'
        ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
        Properties: {
          DomainName: adDomainName
          AdminCreds: {
            UserName: adminUsername
            Password: 'PrivateSettingsRef:AdminPassword'
          }
        }
      }
      protectedSettings: {
        Items: {
          AdminPassword: adminPassword
        }
      }
    }
    tags: tags
  }
}

resource maintenanceConfiguration 'Microsoft.Maintenance/maintenanceConfigurations@2023-10-01-preview' = {
  name: '${vmName}-maintenance-configuration'
  location: location
  properties: {
    extensionProperties: {
      InGuestPatchMode: 'User'
    }
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      startDateTime: '2025-01-12 00:00'
      duration: '03:55'
      timeZone: 'W. Europe Standard Time'
      recurEvery: '1Day'
    }
    visibility: 'Custom'
    installPatches: {
      rebootSetting: 'IfRequired'
      linuxParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
      }
      windowsParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
      }
    }
  }
}

@description('The name of the virtual machine.')
output vmName string = vm.outputs.name

@description('The resource ID of the virtual machine.')
output vmResourceId string = vm.outputs.resourceId

@description('The resource ID of the maintenance configuration.')
output maintenanceConfigurationResourceId string = maintenanceConfiguration.id
