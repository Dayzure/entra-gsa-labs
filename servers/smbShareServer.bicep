param location string = resourceGroup().location
param adDomainName string
param subnetResourceId string
param tags object
param adminUsername string
@secure()
param adminPassword string
param namePrefix string = 'gsalab'

var vmName = '${namePrefix}-smb'

module smbVm 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: vmName
  params: {
    name: vmName
    location: location
    vmSize: 'Standard_B2s'
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
    nicConfigurations: [
      {
        name: '${vmName}-nic'
        privateIPAddressVersion: 'IPv4'
        deleteOption: 'Delete'
        enableAcceleratedNetworking: false 
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
    extensionDomainJoinConfig: {
      enabled: true
      settings: {
        name: adDomainName
        // ouPath: 'CN=Computers,DC=M365x82796325,DC=onmicrosoft,DC=com'
        user: '${adDomainName}\\${adminUsername}'
        restart: 'true'
        options: 3        
      }
    }
    extensionDomainJoinPassword: adminPassword
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

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  name: '${vmName}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Dayzure/entra-gsa-labs/refs/heads/main/PoSH/CreateFileShare.ps1'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File CreateFileShare.ps1 -DomainUsername "${adDomainName}\\${adminUsername}" -DomainPassword "${adminPassword}"'
      adminUsername: '${adDomainName}\\${adminUsername}'
      adminPassword: adminPassword
    }
  }
  dependsOn: [
    smbVm
  ]
}

@description('The name of the virtual machine.')
output vmName string = smbVm.outputs.name

@description('The resource ID of the virtual machine.')
output vmResourceId string = smbVm.outputs.resourceId

@description('The resource ID of the maintenance configuration.')
output maintenanceConfigurationResourceId string = maintenanceConfiguration.id
