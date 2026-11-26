Function Write-MSEConfig
{
    <#
        .SYNOPSIS

            Will write the Local MSEConfig to a JSON file.    
 
        .DESCRIPTION

            Will write the Local MSEConfig to a JSON.   If a location and name parameter are provided, other configuration variables can be loaded.
 
        .PARAMETER ConfigRoot

            By default ConfigRoot is set to C:\MSEAutomation\Config.    Can be set to any other directory with a supplied parameter value.

        .PARAMETER ConfigFile

            By default ConfigFile is set to the name of the host as <hostname>.json.    Can be set to any other filename with a supplied parameter value.
 
        .EXAMPLE

            Get-MSEConfig -ConfigFile MyConfig.json
 
        .NOTES
 
            FunctionName : Write-MSEConfig
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
        $Global:MSEConfig | ConvertTo-JSON | Set-Content $MyConfigFile
        $LocalConfig = Get-Content $MyConfigFile | ConvertFrom-JSON
        If (($Global:MSEConfig|ConvertTo-JSON) -eq ($LocalConfig|ConvertTo-JSON)) {
#	        Write-MSELog " - - Configuration file was written and read correctly."
	        Write-host " - - Configuration file was written and read correctly."
        } else {
#	        Write-MSELog " - - Configuration file was NOT written and read correctly."
	        Write-host " - - Configuration file was NOT written and read correctly."
        }
    }
    End
    {
    }
}