# Create-MSEModule.ps1
<#
    .SYNOPSIS
       This script is designed to take the functions built within Git for the MSEAutomation Project and build a single Module.

    .DESCRIPTION
       This script is designed to take the functions built within Git for the MSEAutomation Project and build a single Module.

      NOTE: Because these functions are all designed to work together within the MSEAutomation environment 
      we have made a concious decision to divert from the normal <verb>-<noun> naming convention
      with PowerShell to <verb>-MSE<noun>.    In this way we can distinguish our purpose built functions
      with other that are available.   While most of our functions can stand alone, they are designed
      for the specific needs of this project.
 
    .PARAMETER
      None
 
    .EXAMPLE
      This script is hard coded for this project.    It should be run from the .\Build directory where it can read the .\MSEBuildEnvironment.ps1 file.

      Powershell .\Create-MSEModule.ps1

    .NOTES
 
        ScriptName   : Create-MSEModule.ps1
        Created by   : Ron Gines
        Date Coded   : 04/15/2021 10:01:10
 
    .LINK
 
        https://github.com/Ron-Gines/TFS-MSE-AutomationInfrastructure
 
 #>

Function Get-MSEUniqueTimeStamp
{
   [CmdletBinding(SupportsShouldProcess=$True)]
   Param ([Parameter(Mandatory=$false)][string]$LogPath)
   
   # Clean up variables and define in-house variables
   $FunctionName  = "Get-MSEUniqueTimeStamp"
   
   If ($LogPath -ne $null)
   {
      If ($LogPath) {Write-MSELogFile $LogPath "$($FunctionName): -------------------------------------" $false}
      If ($LogPath) {Write-MSELogFile $LogPath "$($FunctionName): >>>>>Loading" $false}
   }
   $CurrentDate = Get-Date -format g
   $DateSplit = $CurrentDate -split "/"
   $xMo = $DateSplit[0]
   if ($xMo.length -eq 1){$xMo = "0$xMo"}
   $xDa = $DateSplit[1]
   if ($xDa.length -eq 1){$xDa = "0$xDa"}
   $DateSplit2 = $DateSplit[2] -split " "
   $xYe = $DateSplit2[0]
   $AMPM = $DateSplit2[2]
   $DateSplit3 = $DateSplit2[1] -split ":"
   $UniqueDate = $xYe+$xMo+$xDa+"."+$DateSplit3[0]+$DateSplit3[1]+$AMPM
   return $UniqueDate

} # End function Get-MSEUniqueTimeStamp

function Test-ManifestBool ($path){$a = dir $path | Test-ModuleManifest -ErrorAction SilentlyContinue; $?}


Write-Output  "Loading Build Environment and Defining variables."

#Load Module Build Environment Variables
. .\MSEBuildEnvironment.ps1

# Clear-Host
$CommandPath               = $PSCommandPath                                                          # Full Path to this script in the Build subdirectory.
$MSEReleaseNotesFile       = $RepositoryRootPath  + '\' + $ReleaseNotesFile
$MSEReleaseDirectory       = $RepositoryRootPath  + '\' + $ReleaseDirectory
If ($HeaderFile.length -gt 0) {
   $MSEHeaderFile             = $RepositoryRootPath  + '\' + $HeaderFile
   }
If ($FooterFile.length -gt 0) {
	$MSEFooterFile             = $RepositoryRootPath  + '\' + $FooterFile
   }

$PublicFunctionPath        = @()
ForEach ($Dir in $PublicFunctionsDirectory) {
	$PublicFunctionPath   += $RepositoryRootPath + '\' + $dir
	}

$PrivateFunctionPath       = @()
ForEach ($Dir in $PrivateFunctionsDirectory) {
	$PrivateFunctionPath  += $RepositoryRootPath + '\' + $dir
	}

$PublicFunctions           = @()
($PublicFunctions          += $PublicFunctionPath | Get-ChildItem -Filter *.ps1 -Recurse ) | Out-Null
$FunctionsToExport         = $PublicFunctions.BaseName
$PrivateFunctions          = @()
($PrivateFunctions         += $PrivateFunctionPath | Get-ChildItem -Filter *.ps1 -Recurse ) | Out-Null
$FunctionsToExclude        = $PrivateFunctions.BaseName
$AllFunctions              = $PublicFunctions + $PrivateFunctions


Write-Output "Collecting $ModuleToBuild Module Manifest Information"
# Building Module psm1 file contents
$fHeader1 = "##################################################################################################################################################"
$fHeader4 = "##################################################################################################################################################"
$CompiledFunctions = "" + $fHeader1 
If ($MSEHeaderFile.length -gt 1){
    $CompiledFunctions = $CompiledFunctions + [environment]::newline  + (get-content -Path $MSEHeaderFile -encoding utf8 -Raw)
   }
$CompiledFunctions = $CompiledFunctions + $fHeader4 + [environment]::newline  + [environment]::newline 


foreach ($Function in $AllFunctions) {
   $MyDir                 = $Function.DirectoryName
   $MyPath                = $MyDir + "\" + $($Function.Name) 
   $MyLogicalPath         = $($MyPath -split 'GitHub')[1]
   $fHeader2              = "# Sourced from file named:"
   $fHeader3              = "#       .$MyLogicalPath"
   $CompiledFunctions     = $CompiledFunctions + [environment]::newline + [environment]::newline 
   $CompiledFunctions     = $CompiledFunctions + $fHeader1 + [environment]::newline 
   $CompiledFunctions     = $CompiledFunctions + $fHeader2 + [environment]::newline 
   $CompiledFunctions     = $CompiledFunctions + $fHeader3 + [environment]::newline 
   $CompiledFunctions     = $CompiledFunctions + $fHeader4 + [environment]::newline 
   $CompiledFunctions     = $CompiledFunctions + [string]::join([environment]::newline, (get-content -Path $Function.fullname -encoding utf8 -Raw))
}
###########################################################
Write-Output "Starting Build process"
If ($MSEFooterFile.length -gt 1){
   $CompiledFunctions = $CompiledFunctions + (get-content -Path $MSEFooterFile)
   }
$mFooter                  = " " + [environment]::newline + [environment]::newline
$CompiledFunctions        = $CompiledFunctions + $mFooter

###########################################################
Write-Output "Collecting version information."
# Get our version from the Release_Notes file
# Version for when Text is required
$MyVersion                = (Get-Content $MSEReleaseNotesFile | Select-String -Pattern '.*v(\d+(\.\d+){1,4}).*' ).matches[0].groups[1].value
# Version when an object is required.
$ModuleVersion            = [System.Version]::Parse($MyVersion)

###########################################################
Write-Output "Creating version target directory."
# Create Build Target Directory
$ReleaseTargetDirectory     = $RepositoryRootPath + '\' + $ReleaseDirectory + '\v' + $MyVersion

#Define our target file names
$MSEModuleFileName        = $ReleaseTargetDirectory + '\' + $ModuleToBuild + '.psm1'
$MSEModuleManifestName    = $ReleaseTargetDirectory + '\' + $ModuleToBuild + '.psd1'

#Check if we need to rename the existing version directory
If (Test-Path -Path $ReleaseTargetDirectory){
	$ExtendedDate = Get-MSEUniqueTimeStamp
	$NewReleaseTargetDirectory = $ReleaseTargetDirectory + '-' + $ExtendedDate
	Rename-Item  $ReleaseTargetDirectory  $NewReleaseTargetDirectory 
}

#Create our new version directory
New-Item -Path $ReleaseTargetDirectory -ItemType Directory > $null


###########################################################
Write-Output "Copying Release-Notes file"
  Copy-Item -Path $MSEReleaseNotesFile -Destination $ReleaseTargetDirectory


###########################################################
Write-Output "Creating Module file."
# Writing out Module File
Set-Content -Path $MSEModuleFileName -Value $CompiledFunctions -Encoding UTF8 -Force

# Building Module psd1 file 
$MyManifest = @{
	Path                  = $MSEModuleManifestName
	RootModule            = Split-Path $MSEModuleFileName -leaf
	CompanyName           = $ModuleCompanyName
	Author                = $ModuleAuthor
	ModuleVersion         = $ModuleVersion
	Copyright             = $ModuleCopyRight
	Description           = $ModuleDescription
	ReleaseNotes          = $ReleaseNotesFile
	FunctionsToExport     = $FunctionsToExport
        RequiredModules       = $RequiredModules
}

###########################################################
Write-Output "Creating Manifest File"
#Create the manifest psd1 file
New-ModuleManifest @MyManifest

# Insert our PrivateData additions to the file.
(Get-Content $MSEModuleManifestName) | 
    Foreach-Object {
        $_ # send the current line to output
        if ($_ -match "} # End of PSData hashtable") 
        {
            #Add Lines after the selected pattern 
            $ModulePrivateData
        }
    } | Set-Content $MSEModuleManifestName


###########################################################
Write-Output "Adding include files into package directory"
If ($ModuleIncludeFiles.count -gt 0){
   ForEach ($File in $ModuleIncludeFiles){
      $MyIncludeFile = $RepositoryRootPath  + '\' + $File
      If (Test-Path $MyIncludeFile) {
         Copy-Item -Path $MyIncludeFile -Destination $ReleaseTargetDirectory
      }
      Else
      {
         Write-Output "$MyIncludeFile could not be found.   Not included in package."
      }
   }
}

###########################################################
Write-Output "Testing Module Manifest"
If (Test-ManifestBool -Path $MSEModuleManifestName){
	Write-Output "Monifest test PASSED"
}else{
	Write-Output "Manifest tests FAILED"
	Write-Output "We will exit now"
	pause
	exit
}

###########################################################
Write-Output "Testing with PSScriptAnalyzer"
Import-Module PSScriptAnalyzer
Invoke-Scriptanalyzer -Path $MSEmoduleFileName -Settings .\PSSCriptAnalyzerSettings.psd1

###########################################################
Write-Output "Future testing with Pester"

#
#
#

###########################################################

###########################################################
Write-Output "Nuget Package Build -----------"
###########################################################
Write-Output "Creating NuSpec file"
## Might incorporate Github/pds1-to-nuspec.ps1 in the future
## https://gist.github.com/tyconsulting/c567e5cc66fc522d46743d744579be27#file-psd1-to-nuspec-ps1
## This is just a quick and dirty way to hash out a nuspec file.

$NuSpecSource = $MSEReleaseDirectory + "\*.*"
$NuSpecTarget = $NuGetTitle
#Need to place here because the NuGetVersion is being rewritten somewhere.
$NuGetVersion = $ModuleVersion.ToString()

$MyNuSpec     = '<?xml version="1.0" encoding="utf-8"?>' + [environment]::newline
$MyNuSpec    += '<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">' + [environment]::newline
$MyNuSpec    += "  <metadata>"  + [environment]::newline
$MyNuSpec    += "    <id>$NuGetID</id>"  + [environment]::newline
$MyNuSpec    += "    <title>$NuGetTitle</title>" + [environment]::newline
$MyNuSpec    += "    <version>$NuGetVersion</version>" + [environment]::newline
$MyNuSpec    += "    <authors>$NuGetAuthors</authors>" + [environment]::newline
$MyNuSpec    += "    <owners>$NuGetOwners</owners>" + [environment]::newline
$MyNuSpec    += "    <description>$NuGetDescription</description>" + [environment]::newline
$MyNuSpec    += "    <summary>$NuGetSummary</summary>" + [environment]::newline
$MyNuSpec    += "    <tags>$NuGetTags</tags>" + [environment]::newline
$MyNuSpec    += "    <projectUrl>$NuGetProjectURL</projectUrl>" + [environment]::newline
$MyNuSpec    += "    <requireLicenseAcceptance>$NuGetRequiredLicenseAcceptance</requireLicenseAcceptance>" + [environment]::newline
$MyNuSpec    += "    <contentFiles>" + [environment]::newline
$MyNuSpec    += '      <files include="*" />' + [environment]::newline
$MyNuSpec    += "    </contentFiles>" + [environment]::newline
$MyNuSpec    += "  </metadata>" + [environment]::newline
$MyNuSpec    += "</package>" + [environment]::newline

$NuSpecFile   = $NuGetTitle + ".nuspec"
$NuSpecPath = Join-Path $ReleaseTargetDirectory $NuSPecFile  
Set-Content -Path $NuSpecPath -Value $MyNuSpec -Encoding UTF8 -Force

###########################################################
# Decided to not do this with nuget.   There seemed to be some incombatibilities with a file share repo that I didn't want to spend time chasing.
# Write-Output "Building NuSpec Package"
# CD $ReleaseTargetDirectory
# nuget pack $NuSpecFile

############################################################
Write-Output "Publishing with Publish-Module to File Share Repository."
$Response = Read-Host "Do you wish to publish this repository?  (yes/no)"
if ($response.ToUpper() -eq "YES"){
	$StagingDir = Join-Path $ReleaseTargetDirectory $ModuleToBuild
	New-Item -Path $StagingDir -ItemType Directory > $null
    $TmpFiles = Join-Path $ReleaseTargetDirectory "*.*"
	Copy-Item $TmpFiles $StagingDir
    Publish-Module -Path $StagingDir -Repository $PublishRepositoryName -Force
    Write-Output "Module $ModuleToBUild published to $PublishRepositoryName Repository."
	#Saving a copy of the built module locally
	$TmpDir = join-path  $RepositoryRootPath  $PublishDirectory
	Save-Module -name $ModuleToBuild -Path $TmpDir
}else{
	# nothing to do
}

exit
# Command to push to our internal repository
# Not using.   Publish-Module instead
# nuget push MSEConfiguration.0.0.2.1.nupkg -source \\USSLO-MPN-NAS01.thermo.com\MSE-Automation-Equip\PowerShellRepository

