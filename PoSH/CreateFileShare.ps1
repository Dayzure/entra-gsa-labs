# Define variables
$groupName = "GSALabsGroup"
$folderPath = "C:\gsa-labs-share"
$shareName = "GSALabsShare"

# Define the user details
$Username = "gsauser"
$Password = ConvertTo-SecureString "SuPeRs3cur3!1975" -AsPlainText -Force
# Get the domain name using WMI
$domainName = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
$OU = "CN=Users,DC=$($domainName -replace '\.',',DC=')"

# Check if the AD module is installed, if not, install it
if (-Not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Install-WindowsFeature -Name RSAT-AD-PowerShell
    Import-Module ActiveDirectory
}

# Create the new user
New-ADUser -Name $Username -SamAccountName $Username -UserPrincipalName "$Username@$domainName.onmicrosoft.com" -Path $OU -AccountPassword $Password -Enabled $true

# Add the user to the "Remote Desktop Users" group
Add-ADGroupMember -Identity "Remote Desktop Users" -Members $Username

# Enable the user for RDP login
$User = Get-ADUser -Identity $Username
Set-ADUser -Identity $User -Add @{"msTSAllowLogon"=$true}

Write-Host "User $Username has been created and enabled for RDP login."

# Create a universal security group in the default domain
New-ADGroup -Name $groupName -GroupScope Universal -GroupCategory Security -Path "CN=Users,DC=$($domainName -replace '\.',',DC=')"

# Add the user to the "Remote Desktop Users" group
Add-ADGroupMember -Identity $groupName -Members $Username

# Check if the folder already exists
if (-Not (Test-Path -Path $folderPath)) {
    # Create a folder under C:\
    New-Item -Path $folderPath -ItemType Directory
}

# Check if the share already exists
if (-Not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
    # Share the folder with the security group
    New-SmbShare -Name $shareName -Path $folderPath -FullAccess "$domainName\$groupName"
}

# Ensure NTFS permissions for the security group
$acl = Get-Acl $folderPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainName\$groupName", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $folderPath $acl

# Ensure share permissions for the security group
Grant-SmbShareAccess -Name $shareName -AccountName "$domainName\$groupName" -AccessRight Full -Force