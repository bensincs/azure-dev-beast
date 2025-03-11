// Parameters
param location string = resourceGroup().location
param sshPublicKey string
param vnetName string
param subnetName string
param addressPrefix string = '10.0.0.0/16'
param subnetPrefix string = '10.0.1.0/24'
param vmName string
param sku string = '20_04-lts-gen2'
param username string

// Minimal NSG Module with SSH Rule
module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'networkSecurityGroupDeployment'
  params: {
    name: '${vnetName}-nsg'
    location: location
    securityRules: [
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Allow SSH from anywhere'
        }
      }
    ]
    tags: {
      Environment: 'Non-Prod'
    }
  }
}

// Virtual Network Module
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.4' = {
  name: 'virtualNetworkDeployment'
  params: {
    addressPrefixes: [addressPrefix]
    name: vnetName
    subnets: [
      {
        addressPrefix: subnetPrefix
        name: subnetName
        networkSecurityGroupResourceId: networkSecurityGroup.outputs.resourceId
      }
    ]
    location: location
    tags: {
      Environment: 'Non-Prod'
    }
  }
}

// Virtual Machine Module
module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.12.2' = {
  name: 'virtualMachineDeployment'
  params: {
    adminUsername: username
    encryptionAtHost: false
    imageReference: {
      offer: '0001-com-ubuntu-server-focal'
      publisher: 'Canonical'
      sku: sku
      version: 'latest'
    }
    name: vmName
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        enableAcceleratedNetworking: true
        ipConfigurations: [
          {
            name: 'ipconfig01'
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
          }
        ]
        name: '${vmName}-nic'
      }
    ]
    osDisk: {
      caching: 'ReadOnly'
      createOption: 'FromImage'
      deleteOption: 'Delete'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
      name: '${vmName}-osdisk'
    }
    osType: 'Linux'
    vmSize: 'Standard_D16s_v5'
    zone: 1
    disablePasswordAuthentication: true
    location: location
    publicKeys: [
      {
        keyData: sshPublicKey
        path: '/home/${username}/.ssh/authorized_keys'
      }
    ]
    tags: {
      Environment: 'Non-Prod'
    }
  }
}


output virtualMachineId string = virtualMachine.outputs.resourceId
