param(
    [string]$DomainUsername,
    [string]$DomainPassword
)

# Convert the password to a secure string
$SecurePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($DomainUsername, $SecurePassword)
# Define variables
$groupName = "GSAUsersPrivateAccess"
$folderPath = "C:\gsa-labs-share"
$shareName = "GSALabsShare"

# Check if the AD module is installed, if not, install it
if (-Not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Install-WindowsFeature -Name RSAT-AD-PowerShell
    Import-Module ActiveDirectory
}

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