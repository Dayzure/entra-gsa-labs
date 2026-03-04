using 'main.bicep'

param tags = {
  Environment: 'GSA-Labs'
}
param resourceLocation = 'westeurope'
param resourceGroupName = 'gsa-lab-rg'
param vmSize = 'Standard_D4ads_v5'
param adminUsername = 'gsadm' 
param adminPassword = 'PWD_PLACEHOLDER'
param adDomainName = 'M365x82796325.onmicrosoft.com'
