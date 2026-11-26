#################################################################################################################################################
# Function Close-MSELogFile
#################################################################################################################################################
<# 
 .SYNOPSIS 
	 This function will close down the log file for us.

 .DESCRIPTION 
	 This function will close down the log file for us.

 .NOTES 
     Author       : 	 Ron Gines
     Date         :      1/15/2016
     Version Date : 	 Version 1.0 - Added to the Infrastructure Functions

     Author       : 	 Ron Gines
     Date         :      04/15/2021
     Version Date : 	 Version 1.1 - Rewritten for the MSEAutomation Infrastructure Functions

 .EXAMPLE   
	 Close-MSELogFile
#> 
Function Close-MSELogFile
{
  [CmdletBinding(SupportsShouldProcess=$True)]
  Param ([Parameter(Mandatory=$true,Position=0)][string]$LogPath
  ) # End Param

  # Clean up variables and define in-house variables
  $FunctionName = "Write-MSELogFile"

  If (!(Test-Path -Path $LogPath)){
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
     (Add-Content -Path $LogPath -Value "Started processing at [$([DateTime]::Now)].")
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
  }
   $FunctionName = "Log-WrapUp"
   Write-MSELogFile $LogPath "$($FunctionName): -------------------------------------" $false
   Write-MSELogFile $LogPath "$($FunctionName): >>>>>Entering" $false

   Write-MSELogFile $LogPath "####################################" $true
   (Add-Content -Path $LogPath -Value "***************************************************************************************************")
   (Add-Content -Path $LogPath -Value "Finished processing at [$([DateTime]::Now)].")
   (Add-Content -Path $LogPath -Value "***************************************************************************************************")
   Write-MSELogFile $LogPath "We should be done with the script.   This should be the last formal entry." $true

   Write-MSELogFile $LogPath "$($FunctionName): <<<<<Exiting" $false
   Write-MSELogFile $LogPath "$($FunctionName): -------------------------------------" $false
} # End Function Close-MSELogFile