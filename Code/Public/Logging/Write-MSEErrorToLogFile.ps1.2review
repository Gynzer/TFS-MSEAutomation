################################################################################################################################################
# Function Write-MSEErrorToLogFile                                                                                                 
#################################################################################################################################################
<# 
  .SYNOPSIS
    Writes an error to a log file

  .DESCRIPTION
    Writes the passed error to a new line at the end of the specified log file
  
  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log
  
  .PARAMETER ErrorDesc
    Mandatory. The description of the error you want to pass (suggest using $_.Exception from within calling script)
  
  .PARAMETER ExitGracefully
    Mandatory. Boolean. Default is $false. If set to $true, runs Log-Finish and then exits script

  .INPUTS
    Parameters above

  .OUTPUTS
    None


  .NOTES
    Version:        1.0
    Author:         Luca Sturlese
    Creation Date:  10/05/12
    Purpose/Change: Initial function development

    Version:        1.1
    Author:         Luca Sturlese
    Creation Date:  19/05/12
    Purpose/Change: Added debug mode support

    Version:        1.2
    Author: 	    Ron Gines
    Date:           02/05/2015
    Change: 	    Cleaned up for use in first NPPC release

    Version:        1.3
    Author: 	    Ron Gines
    Date:           04/14/2021
    Change: 	    Cleaned up for use in first MSE release

  .EXAMPLE
    Write-MSEErrorToLogFile -LogPath "C:\Windows\Temp\Test_Script.log" -ErrorDesc $_.Exception -ExitGracefully $True
#>
#####################
#####################
# TODO: Need to add option to output to screen as well with red coloring.
#####################
#####################

Function Write-MSEErrorToLogFile
{
  [CmdletBinding(SupportsShouldProcess=$True)]
  Param ([Parameter(Mandatory=$true,Position=0)][string]$LogPath, 
         [Parameter(Mandatory=$true,Position=1)][string]$ErrorDesc, 
         [Parameter(Mandatory=$false,Position=2)][boolean]$ExitGracefully
  )
  
  $FunctionName = "Write-MSEErrorToLogFile"
    If (!(Test-Path -Path $LogPath)){
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
     (Add-Content -Path $LogPath -Value "Started processing at [$([DateTime]::Now)].")
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
  }

  Write-MSELogFile $LogPath "$($FunctionName): -------------------------------------" $false
  Write-MSELogFile $LogPath "$($FunctionName): >>>>>Loading" $false

  Write-MSELogFile $LogPath -Value "ERROR: An error has occurred [$ErrorDesc]."
   
  #Write to screen for debug mode
  Write-Debug "ERROR: An error has occurred [$ErrorDesc]."
    
  #If $ExitGracefully = True then run Log-Finish and exit script
  If ($ExitGracefully -eq $True){
    Write-MSELogFile $LogPath "Exiting as instructed after an error." $true
    Exit-MSEScript -LogPath $LogPath -ScriptExit $True
    Break
  }
} # End Function Write-MSEErrorToLogFile
