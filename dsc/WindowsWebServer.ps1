Configuration WindowsWebServer {

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xWebAdministration

    Node localhost {

        WindowsFeature WebServerRole
        {
		    Name = "Web-Server"
		    Ensure = "Present"
        }

        WindowsFeature WebManagementConsole
        {
            Name = "Web-Mgmt-Console"
            Ensure = "Present"
        }

        WindowsFeature WebManagementService
        {
            Name = "Web-Mgmt-Service"
            Ensure = "Present"
        }

        WindowsFeature ASPNet45
        {
		    Ensure = "Present"
		    Name = "Web-Asp-Net45"
        }

        WindowsFeature HTTPRedirection
        {
            Name = "Web-Http-Redirect"
            Ensure = "Present"
        }

        WindowsFeature CustomLogging
        {
            Name = "Web-Custom-Logging"
            Ensure = "Present"
        }

        WindowsFeature LogginTools
        {
            Name = "Web-Log-Libraries"
            Ensure = "Present"
        }

        WindowsFeature RequestMonitor
        {
            Name = "Web-Request-Monitor"
            Ensure = "Present"
        }

        WindowsFeature Tracing
        {
            Name = "Web-Http-Tracing"
            Ensure = "Present"
        }

        WindowsFeature BasicAuthentication
        {
            Name = "Web-Basic-Auth"
            Ensure = "Present"
        }

        WindowsFeature WindowsAuthentication
        {
            Name = "Web-Windows-Auth"
            Ensure = "Present"
        }

        WindowsFeature ApplicationInitialization
        {
            Name = "Web-AppInit"
            Ensure = "Present"
        }

        WindowsFeature IISManagement  
        {  
            Ensure          = 'Present'
            Name            = 'Web-Mgmt-Console'
            DependsOn       = '[WindowsFeature]WebServerRole'
        } 
  
        xWebsite DefaultSite   
        {  
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            PhysicalPath    = 'C:\inetpub\wwwroot' 
            DependsOn       = '[WindowsFeature]WebServerRole'
        }
      }
}
