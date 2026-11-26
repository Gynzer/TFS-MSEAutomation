#################################################################################################################################################
# Function Add-MSEEventLogSource                                                                                        
#################################################################################################################################################
<# 
 .SYNOPSIS 
	 This function will set up an Event source in the local Windows Event Logs called "MSE-Scripts"

 .DESCRIPTION 
	 This function will set up an Event source in the local Windows Event Logs called "MSE-Scripts".   
     This will allow us to make calls from our scripts that will record specific events and errors 
     into the event log that can be searched under this source name.   This will be in addition to 
     the PowerShell event loggin whcih will be turned on for each Windows System.   This will allow
     for our own event messages to be placed in the Windows Event Log.

 .NOTES 
     Author       : 	 Ron Gines
     Date         :      1/15/2016
     Version Date : 	 Version 1.0 - Original scritp by Ron Gines.  Added to the Infrastructure Functions.

     


 .EXAMPLE   
	 Add-MSEEventLogSource
#> 
Function Add-MSEEventLogSource 
{
  $FunctionName = "Add-MSEEventLogSource"
  Log-MSEWrite $ScriptLogFullName "$($FunctionName): -------------------------------------" $false
  Log-MSEWrite $ScriptLogFullName "$($FunctionName): >>>>>Loading" $false

   if ([System.Diagnostics.EventLog]::SourceExists("MSE-Scripts"))
   {
      Log-MSEWrite $ScriptLogFullName "'MSE-Scripts' already exists as an Event Log Source on this system." $true
   }
   else
   {
      Try
      {
         New-EventLog -LogName Application -Source "MSE-Scripts"
         Log-MSEWrite $ScriptLogFullName "'MSE-Scripts' was successfully added as an Event Log Source on this system." $true
      }
      Catch
      {
         Log-MSEWrite $ScriptLogFullName "'MSE-Scripts' was successfully added as an Event Log Source on this system." $true
         Log-MSEWrite $ScriptLogFullName "$($FunctionName): User Creation function for $($NewUserID) Failed." $true
         Log-MSEWrite $ScriptLogFullName "$($FunctionName): Error Message: $_.Exception.Message" $true
         Log-MSEWrite $ScriptLogFullName "$($FunctionName): Filed Item   : $_.Exception.ItemName " $true
      }
   }

#  Example:
#  Write-EventLog -Logname Application -Source "MSE-Scripts" -EntryType Information 1 -Message "VersionChecks: Script VersionCheck is starting."

} # End Function Add-MSEEventLogSource