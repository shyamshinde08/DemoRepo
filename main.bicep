param location string = resourceGroup().location
param userName string
@secure()
param password string
param vmName string
param vmSize string
param nicName string
@secure()
param subnetRef string
param extName string
@secure()
param customScriptFileUrl string
param commandToExecute string
param userIdColl array 

targetScope = 'resourceGroup'

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for userId in userIdColl:  {
  name: '${userId}-${nicName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: null
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = [for (userId, i) in userIdColl: {
  name: '${userId}-${vmName}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${userId}-${vmName}'
      adminUsername: userName
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [ 
        {
          id: nic[i].id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-21h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: null
        }
      }
      dataDisks: [
        {
          diskSizeGB: 128
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
  }
}]

resource vmExtensions 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for userId in userIdColl: {
  name: '${userId}-${vmName}/${extName}'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptFileUrl
      ]
      commandToExecute: commandToExecute
    }
  }
  dependsOn:[
    vm
  ]
}]
