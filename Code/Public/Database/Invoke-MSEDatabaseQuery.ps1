#################################################################################################################################################
# Function Invoke-MSEDatabaseQuery                                                                                                              #
#################################################################################################################################################

<#
 .SYNOPSIS
    This function will run a non-data query against an SQL Server Database
 .DESCRIPTION
    This function will run a non-data query against an SQL Server Database
 .NOTES 
     Author       : 	 Ron Gines
     Version      : 	 Version 1.0 
     Date         :      09/16/2021
     Info         :      Initial release of script.
 .PARAMETER connectionString
     This is the connection string for the database to be connected to.
	 Example format  "Server=USSLO-MSE-DB01;Integrated Security=true;Initial Catalog=MSEAutomation"
 .PARAMETER query
     The query to be run against the database.
 .EXAMPLE
	 $MyResult = Invoke-MSEDatabaseQuery -connectionstring "Server=USSLO-MSE-DB01;Integrated Security=true;Initial Catalog=MSEAutomation" -query "SELECT * from MSEEventLog"
    
#>  
function Invoke-MSEDatabaseQuery {
  [CmdletBinding()]
  param (
    [string]$connectionString,
    [string]$query
  )
  $FunctionName = "Invoke-MSEDatabaseQuery"
  Write-MSELog $ScriptLogFullName "$($FunctionName): -------------------------------------" $false
  Write-MSELog $ScriptLogFullName "$($FunctionName): >>>>>Loading $($FunctionName)" $false
  [boolean]$Result = $False
  Try 
  {
    Write-MSELog $ScriptLogFullName "$($FunctionName): Entering TRY:" $false
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $connection.Open()
    $command.ExecuteNonQuery()
    $connection.close()
    $Result = $true
    Write-MSELog $ScriptLogFullName "$($FunctionName): Our DB Query Worked!!!!" $true
    Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting TRY:" $false
  } # EndTry
  Catch 
  {
    Write-MSELog $ScriptLogFullName "$($FunctionName): Entering CATCH:" $false
    #
    # Add Code Here
    #
    $Return = $false
    Write-MSELog $ScriptLogFullName "$($FunctionName): It Didn't Work!!!!"
    Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting CATCH:" $false
  } # EndCatch
  Finally 
  {
    Write-MSELog $ScriptLogFullName "$($FunctionName): Entering FINALLY:" $false
    #
    # XXX Add code here
    #
    Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting FINALLY:" $false
  } # EndFinally
  Write-MSELog $ScriptLogFullName "$($FunctionName): <<<<<Exiting $($FunctionName) with result: $($Result))" $false
  Write-MSELog $ScriptLogFullName "$($FunctionName): -------------------------------------" $false
  Return $Result
} # End Function Invoke-NPEDatabaseQuery


