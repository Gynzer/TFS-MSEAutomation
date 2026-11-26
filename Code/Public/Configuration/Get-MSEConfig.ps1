Function Get-MSEConfig
{
    <#
        .SYNOPSIS

            Will load the Local MSEConfig by default.    
 
        .DESCRIPTION

            Will load the Local MSEConfig by default.   If a location and name parameter are provided, other configuration variables can be loaded.
 
        .PARAMETER ConfigRoot

            By default ConfigRoot is set to C:\MSEAutomation\Config.    Can be set to any other directory with a supplied parameter value.

        .PARAMETER ConfigFile

            By default ConfigFile is set to the name of the host as <hostname>.json.    Can be set to any other filename with a supplied parameter value.
 
        .EXAMPLE

            Get-MSEConfig -ConfigFile MyConfig.json
 
        .NOTES
 
            FunctionName : Get-MSEConfig
            Used In      : MSEAutomation Module.
            Created by   : ron gines
            Date Coded   : 09/13/2021 16:45:13
 
        .LINK
 
            https://github.com/Ron-Gines 
 
    #>
 
    [CmdletBinding()]
 
    Param(
        [Parameter(Mandatory=$false)] [string]$ConfigRoot="C:\MSEAutomation\Config",
        [Parameter(Mandatory=$false)] [string]$ConfigFile=(HOSTNAME) + ".json"
        )
 
    Begin
    {
        $MyConfigFile = $ConfigRoot + "\" + $ConfigFile
    }
 
    Process
    {
        $LogLine = "Checking for existance of configuration file $MyConfigFile."
#        Write-MSELog
        If (Test-Path "$MyConfigFile"){
            $LogLine = "$MyConfigFile found.  Loading config into $ConfigName variable."
#            Write-MSELog
            $temp = Get-Content -Path $MyConfigFile | ConvertFrom-JSON
            Set-variable -Name MSEConfig  -value  $temp
        }Else{
            $LogLine = "$MyConfigFile was not found."
#            Write-MSELog
            Set-variable -Name MSEConfig  -value  $null
        }	
    }
    End
    {
        return $MSEConfig
    }
}