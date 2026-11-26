#################################################################################################################################################
# Function Get-MSEUniqueTimeStamp                                                                                          
#################################################################################################################################################
<# 
   .SYNOPSIS 
	  Function will return a character strng that can be used in timestamping a file name.

   .DESCRIPTION 
	  Function will return a character strng that can be used in timestamping a file name.

   .PARAMETER
      LogePath (required).   Specify the log path for the log file to be written to.

   .NOTES 
      Author       : 	Ron Gines
      Version      :    1.0
      Date         : 	05/05/2016
      Description  :    Cleaned up for first NPPC release

      Author       : 	Ron Gines
      Version      :    1.1
      Date         : 	04/14/2021
      Description  :    Cleaned up for first MSE release

   .EXAMPLE   
	  $CharacterString = Get-MSEUniqueTimeStamp
#> 
Function Get-MSEUniqueTimeStamp
{
   [CmdletBinding(SupportsShouldProcess=$True)]
   Param ([Parameter(Mandatory=$false)][string]$LogPath)
   
   # Clean up variables and define in-house variables
   $FunctionName  = "Get-MSEUniqueTimeStamp"
   
   If ($LogPath -ne $null)
   {
      If ($LogPath) {Write-MSELog $LogPath "$($FunctionName): -------------------------------------" $false}
      If ($LogPath) {Write-MSELog $LogPath "$($FunctionName): >>>>>Loading" $false}
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
