#################################################################################################################################################
# Function Get-MSEDatabaseData                                                                                                                  #
#################################################################################################################################################

<#
 .SYNOPSIS
    This function will run a data query against an SQL Server Database
 .DESCRIPTION
    This function will run a data query against an SQL Server Database
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
	 $MyResult = Get-MSEDatabaseData -connectionstring "Server=USSLO-MSE-DB01;Integrated Security=true;Initial Catalog=MSEAutomation" -query "SELECT * from MSEEventLog"
    
#>  
function Get-MSEDatabaseData {
  [CmdletBinding()]
  param (
    [string]$connectionString,
    [string]$query
  )
  $FunctionName = "Get-MSEDatabaseData"
  Write-MSELog $ScriptLogFullName "$($FunctionName): -------------------------------------" $false
  Write-MSELog $ScriptLogFullName "$($FunctionName): >>>>>Loading $($FunctionName)" $false
  Try 
  {
    Write-MSELog $ScriptLogFullName "$($FunctionName): Entering TRY:" $false
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
	$connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object -TypeName System.Data.DataSet
    [void]    $adapter.Fill($dataset)
# Write-Host "$($FunctionName): $($dataset.Tables[0])"
#    $dataset.Tables[0]
    Write-MSELog $ScriptLogFullName "$($FunctionName): Query was successful." $true
    Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting TRY:" $false
  } # EndTry
  Catch 
  {
    Write-MSELog $ScriptLogFullName "$($FunctionName): Entering CATCH:" $false
    #
    # Add Code Here
    #
    $dataset = $null
    Write-MSELog $ScriptLogFullName "$($FunctionName): Query Didn't Work!!!!"
    Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting CATCH:" $false
  } # EndCatch
  Finally 
  {
    #Write-MSELog $ScriptLogFullName "$($FunctionName): Entering FINALLY:" $false
    #
    # XXX Add code here
    #
    #Write-MSELog $ScriptLogFullName "$($FunctionName): Exiting FINALLY:" $false
  } # EndFinally
  Write-MSELog $ScriptLogFullName "$($FunctionName): <<<<<Exiting $($FunctionName) with result: $($Result))" $false
  Write-MSELog $ScriptLogFullName "$($FunctionName): -------------------------------------" $false
  $connection.Close()
#  $adapter.Close()
  Return,$dataset
################    
} # End Function Get-MSEDatabaseData