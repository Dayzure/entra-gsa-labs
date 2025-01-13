param location string = resourceGroup().location
param adDomainName string
param subnetResourceId string
param tags object
param adminUsername string
@secure()
param adminPassword string
param namePrefix string = 'gsalab'


var vmName = '${namePrefix}-adds'

module vm 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: vmName
  params: {
    name: vmName
    location: location
    vmSize: 'Standard_D4s_v3'
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
        enablePublicIPAddress: true
        ipConfigurations: [
          {
            name: '${vmName}-ipconfig-v4'
            publicIPAddressVersion: 'IPv4'
            privateIPAddressVersion: 'IPv4'
            subnetResourceId: subnetResourceId
            pipConfiguration: {
              publicIPAddressResourceId: vm_pip_v4.outputs.resourceId
            }
          }
        ]
      }
    ]
    extensionDSCConfig: {
      enabled: true
      settings: {
        ModulesUrl: 'https://github.com/Azure/azure-quickstart-templates/raw/refs/heads/master/application-workloads/active-directory/active-directory-new-domain/DSC/CreateADPDC.zip'
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

module vm_pip_v4 'br/public:avm/res/network/public-ip-address:0.7.1' = {
  name: '${vmName}-pip-v4'
  params: {
    name: '${vmName}-pip-v4'
    dnsSettings: {
      domainNameLabel: '${namePrefix}adds'
      domainNameLabelScope: 'ResourceGroupReuse'
      fqdn: '${namePrefix}adds.${location}.cloudapp.azure.com'
    }
    location: location
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
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

// module storage 'br/public:avm/res/storage/storage-account:0.5.0' = {
//   name: '${vmName}-storage'
//   params: {
//     name: uniqueString('${vmName}storage', resourceGroup().id, subscription().subscriptionId)
//     location: location
//     kind: 'StorageV2'
//     skuName: 'Standard_LRS'
//     allowSharedKeyAccess: true
//     tags: tags
//     roleAssignments: [
//       {
//         principalType: 'ServicePrincipal'
//         principalId: vm.outputs.systemAssignedMIPrincipalId
//         roleDefinitionIdOrName: 'Storage Blob Data Contributor'
//       }
//     ]
//   }
// }

@description('The name of the virtual machine.')
output vmName string = vm.outputs.name

@description('The resource ID of the virtual machine.')
output vmResourceId string = vm.outputs.resourceId

@description('The resource ID of the maintenance configuration.')
output maintenanceConfigurationResourceId string = maintenanceConfiguration.id
