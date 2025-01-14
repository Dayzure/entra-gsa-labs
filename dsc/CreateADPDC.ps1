configuration CreateADPDC 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot, xGroupPolicy, GroupPolicyDsc
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential ]$UserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\gsauser", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS { 
            Ensure = "Present" 
            Name   = "DNS"		
        }

        Script GuestAgent
        {
            SetScript  = {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value DNS
                Write-Verbose -Verbose "GuestAgent depends on DNS"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }
        
        Script EnableDNSDiags {
            SetScript  = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber  = 2
            DriveLetter = "F"
            DependsOn   = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall { 
            Ensure    = "Present" 
            Name      = "AD-Domain-Services"
            DependsOn = "[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools {
            Ensure    = "Present"
            Name      = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter {
            Ensure    = "Present"
            Name      = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath                  = "F:\NTDS"
            LogPath                       = "F:\NTDS"
            SysvolPath                    = "F:\SYSVOL"
            DependsOn                     = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        } 

        xADUser GSAUser {
            DomainName = $DomainName
            UserName = "gsauser"
            Ensure = "Present"
            Password = $UserCreds
            DomainAdministratorCredential = $DomainCreds
            GivenName = "Gsa"
            Surname = "User"
            UserPrincipalName = "gsauser@${DomainName}"
            EmailAddress = "gsauser@${DomainName}"            
        }

        xADGroup GSAUsersPrivateAccess {
            GroupName = "GSAUsersPrivateAccess"
            GroupScope = "Universal"
            Category = "Security"
            Ensure = "Present"
            MembersToInclude = @("gsauser")
            DependsOn = "[xADDomain]FirstDS"
        }

        xADGroup RemoteDesktopUsers {
            GroupName = "Remote Desktop Users"
            GroupScope = "DomainLocal"
            Category = "Security"
            Ensure = "Present"
            MembersToInclude = @("GSAUsersPrivateAccess")
            Credential = $DomainCreds
            DependsOn = "[xADDomain]FirstDS"
        }

        # Create the GPO
        xGPO AddRemoteDesktopUsersToLogonPolicy
        {
            Ensure = 'Present'
            Name = 'Add Remote Desktop Users to Logon Policy'
            Domain = $DomainName
            DependsOn = '[xADDomain]FirstDS'
        }

        xGPRegistryValueList AllowDefaultCredentials {
            Name = 'Add Remote Desktop Users to Logon Policy'
            Key = 'HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services'
            Value = "Remote Desktop Users"
            ValueName = 'SeRemoteInteractiveLogonRight'
            Type = 'MultiString'
        }

        xGPLink LinkRemoteDesktopUsersGPO
        {
            Ensure = 'Present'
            Name = 'Add Remote Desktop Users to Logon Policy'
            Target = "dc=$($DomainName.Replace('.', ',dc='))"
            LinkEnabled = 'Yes'
            Enforced = 'Yes'
            DependsOn = '[xGPO]AddRemoteDesktopUsersToLogonPolicy'
        }

        Script UpdateGroupPolicy
        {
            SetScript = {
                Invoke-GPUpdate -Computer "*" -RandomDelayInMinutes 0
            }
            GetScript = { @{} }
            TestScript = { $false }
            DependsOn = '[xGPLink]LinkRemoteDesktopUsersGPO'
        }   
    }
} 
