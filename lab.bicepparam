using 'main.bicep'

param tags = {
  Environment: 'GSA-Labs'
}
@description('Azure region where all the resources shall be created. Pay attention to location availability of Azure Bastion: https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/table')
param resourceLocation = 'westeurope'
param resourceGroupName = 'gsa-lab-rg'
param adminUsername = 'gsadm' 
param adminPassword = '!SuperSecureGenerated!'
param adDomainName = 'M365x82796325.onmicrosoft.com'
