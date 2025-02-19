using 'main.bicep'

param tags = {
  Environment: 'GSA-Labs'
}
@description('Azure region where all the resources shall be created. Pay attention to location availability of Azure Bastion: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table')
param resourceLocation = 'westeurope'
param resourceGroupName = 'gsa-lab-rg'
@description('The virtual machine SKU to use. Please make sure the chosen SKU is available in your region (https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table). Also, be aware that we attache StandardSSD_LRS disks to the VM - so choose a SKU that supports them.')
param vmSize = 'Standard_D4ads_v5'
param adminUsername = 'gsadm' 
@description('Use a complex password that will meet Azure VM password complexity requriements.')
param adminPassword = '********'
param adDomainName = 'M365x82796325.onmicrosoft.com'
