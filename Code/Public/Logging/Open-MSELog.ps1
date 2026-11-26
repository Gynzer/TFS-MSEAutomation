#################################################################################################################################################
# Function Open-MSELog                                                                                               
#################################################################################################################################################
<# 
  .SYNOPSIS
    Creates a local text log file log file

  .DESCRIPTION
    Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
    Once created, writes initial logging data

  .PARAMETER LogPath
    Required. Full Path and file name of where log is to be created. Do not include the trailing '\'   .Example: C:\Windows\Temp\Test_Script.log

  .PARAMETER ScriptVersion
    Required. Version of the running script which will be written in the log. Example: 1.5

  .INPUTS
    Parameters above

  .OUTPUTS
    Log file created

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

    Version:        1.4
    Author: 	    Ron Gines
    Date:           09/14/2021
    Change: 	    Modified to support new logging everything process.

  .EXAMPLE
    Open-MSELogFile -LogPath "C:\Windows\Temp\Test_Script.log" -ScriptVersion "1.5"
  #>
   
Function Open-MSELog
{
  [CmdletBinding(SupportsShouldProcess=$True)]
  
  Param ([Parameter(Mandatory=$true)][string]$LogPath, 
         [Parameter(Mandatory=$true)][string]$ScriptVersion
  ) # End Param

  # Clean up variables and define in-house variables

  $FunctionName = "Open-MSELogFile"
  $nl           = "`n`r"

  #Check if file exists and delete if it does
  If(Test-Path -Path $LogPath){
    Remove-Item -Path $LogPath -Force
  }
    
  #Create file and start logging
  Set-Content -Path $LogPath -Value "Begin Log $nl"  
  $MyContent              = "***************************************************************************************************$nl"
  $MyContent = $MyContent + "In $($FunctionName): Started processing at [$([DateTime]::Now)].$nl"
  $MyContent = $MyContent + "***************************************************************************************************$nl"
  $MyContent = $MyContent + $nl
  $MyContent = $MyContent + "Function Name: [$FunctionName]$nl"
  $MyContent = $MyContent + "Running script version [$ScriptVersion].$nl"
  $MyContent = $MyContent + $nl
  $MyContent = $MyContent + "***************************************************************************************************$nl"
  $MyContent = $MyContent + $nl

  Add-Content -Path $LogPath -Value $MyContent
  
  #Write to screen for debug mode
  Write-Debug $MyContent
  
} # End function Open-MSELog
