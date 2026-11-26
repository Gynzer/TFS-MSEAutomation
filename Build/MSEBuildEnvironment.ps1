<#  MSEBuildEnvironment.ps1

This is simply a variable script which defines the MSEAutomation Build environment.   

#>

$RepositoryRootPath        = "C:\Users\ron.gines\OneDrive - Thermo Fisher Scientific\Documents\GitHub\MSEAutomation"
$PublishRepositoryName     = "MSE-PSRepository"
$PublishRepositoryPath     = "\\USSLO-MPN-NAS01.thermo.com\MSE-Automation-Equip\PowerShellRepository"

#The following directories are identified relative to the RepositoryRootPathPath
$BuildDirectory            = "Build"
$TestDirectory             = "Tests"
$ReleaseDirectory          = "Release"
$PublishDirectory          = "Publish"
# PublicFunctionsDirectory and PrivateFunctionsDirectory are designed to be an array of directories
$PublicFunctionsDirectory  = @(
	"Code\Public"
    )
$PrivateFunctionsDirectory = @(
    "Code\Private"
	)
	
# Required modules is an array of hashtables with a minimum of 'ModuleName' and 'MaximumVerison' as keys with valid values.
# $RequiredModules           = @('MSEConfiguration')
$RequiredModules           = @()

# ModuleIncludeFiles will package these files into the Release directory.
$ModuleIncludeFiles        = @()
    
#Files relative to $RepositoryRootPath
$ReleaseNotesFile          = "Release-Notes.md"
$HeaderFile                = ""
$FooterFile                = ""


#Module Manifest Data - Examples are included below
$ModuleToBuild             = "MSEAutomation"
$ModuleVersion             = "0.0.1"
$ModuleWebsite             = "https://github.com/Ron-Gines/MSEAutomation"
$ModuleCopyright           = "(c) $((get-date).Year.ToString()) Thermo Fisher Scientific. All rights reserved."
$ModuleLicenseURI          = ""
$ModuleTags                = "MSE,Automation,Module" -split ','
$ModuleAuthor              = "Ron Gines"
$ModuleDescription         = "A PowerShell Infrastructure platform to facilitate the Automation of OT devices and systems."
$ModuleEncoding            = "uft8"
$ModuleCompanyName         = "Thermo Fisher Scientific" 
$ModuleAuthor              = 'Ron Gines'
$ModuleIncludeFiles        = @()
    
# Due to issues with the New-Modulemanifest not dealing with nested PrivateData, this is a multiline string that will be added 
# directly to the create psd1 file.   
# The following section is just an example to show context and syntax
$ModulePrivateData         = ""
#Settings to supply to the nuget packaging tool.
$NugetPSRepository              = $PublishRepositoryPath
$NuGetID                        = $ModuleToBuild
$NugetTitle                     = $ModuleToBuild
$NuGetVersion                   = $ModuleVersion.ToString()
$NuGetAuthors                   = $ModuleAuthor
$NuGetOwners                    = $ModuleCompanyName
$NuGetDescription               = $ModuleDescription
$NuGetSummary                   = $ModuleDescription
$NuGetTags                      = $ModuleTags
$NuGetProjectURL                = $ModuleWebSite
$NuGetLicenseUrl                = $ModuleLicenseURI
$NuGetRequiredLicenseAcceptance = "false"
$NuGetDependencies              = ""
$NuGetFiles                     = ""
