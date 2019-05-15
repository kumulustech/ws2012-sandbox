# https://docs.microsoft.com/en-us/powershell/dsc/quickstarts/website-quickstart
Configuration TestWebsiteConfig {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The first resource block ensures that the Web-Server (IIS) feature is enabled.
        WindowsFeature WebServer {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        # The second resource block ensures that the website content copied to the website root folder.
        File WebsiteContent {
            Ensure = 'Present'
            SourcePath = 'c:\s3-files\test-website\index.htm'
            DestinationPath = 'c:\inetpub\wwwroot'
        }
    }
}