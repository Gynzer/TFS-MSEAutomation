####################################################################################################################################################################################################################################################################################################



##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Configuration\Get-MSEConfig.ps1
##################################################################################################################################################
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

##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Configuration\Write-MSEConfig.ps1
##################################################################################################################################################
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

##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Database\Get-MSEDatabaseData.ps1
##################################################################################################################################################
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

##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Database\Invoke-MSEDatabaseQuery.ps1
##################################################################################################################################################
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




##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Logging\Get-MSEUniqueTimeStamp.ps1
##################################################################################################################################################
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


##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Logging\Open-MSELog.ps1
##################################################################################################################################################
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


##################################################################################################################################################
# Sourced from file named:
#       .\MSEAutomation\Code\Public\Logging\Write-MSELog.ps1
##################################################################################################################################################
#################################################################################################################################################
# Function Write-MSELog                                                                                                   
#################################################################################################################################################
<# 
  .SYNOPSIS
    Writes to log sources (Log File, Local Event Log, Screen, Central SQL Event Log)

  .DESCRIPTION
    Writes to log sources (Log File, Local Event Log, Screen, Central SQL Event Log)

  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log
  
  .PARAMETER LogSum
    Mandatory. The short summary string that you want to write to the log
	
  .PARAMETER LogDetail
    Optional. Additional string informatin that you want to write to the log.   If blank, the LogSum value will be used.
	
  .PARAMETER LogLevel
    Default is Info.   Values are 'Info'rmational, 'Warn'ing,  'Error'
	
  .PARAMETER SQLConnectionString
    Connection String for the database you will be writing to.   The default connection is to the database server and database defined within $MSEConfig

  .PARAMETER Screen
    Boolean.   Will write log string out to screen if value is $true.  Default is $false

  .PARAMETER EventLog
    Boolean.   Will write log string out to local event Log if $true.  Default is $false.   Assumes that the MSEAutomation application event log is setup on the local system.

  .PARAMETER EventID
    Optional Parameter if you want to supply a specific eventID to the local system Event Log.   Default value is '0000'

  .PARAMETER SQL
    Boolean.   Will write log string out to SQL Logging database if $true.  Default is $false
	
  .PARAMETER ExitOnError
    Boolean.   If selected, will close everything out after an error is reported.

  .INPUTS
    Parameters above

  .OUTPUTS
    TO logfile, screen, SQL database or event log based on input parameters.

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
    Change: 	    Rewrite to support new logging 'everything' process.
	
	
  .EXAMPLE
    Log File Only Output
    Write-MSELogFile -LogPath "C:\Windows\Temp\Test_Script.log" -LogSum "This is a new line." -LogDetail "This is a new line which I am appending to the end of the log file." -LogLevel "Info"

  .EXAMPLE
    LogFile and Screen Output
    Write-MSELogFile -LogPath "C:\Windows\Temp\Test_Script.log" -LogSum "This is a new line." -LogDetail "This is a new line which I am appending to the end of the log file." -LogLevel "Info" -Screen

  .EXAMPLE
    LogFile and Database Output
    Write-MSELogFile -LogPath "C:\Windows\Temp\Test_Script.log" -LogSum $MyLogSummary -LogDetail $MyLogDetail -LogLevel "Info" -SQLConnectionString $SQLCnnctStrng -SQL
  #>
  
Function Write-MSELogFile
{
  [CmdletBinding(SupportsShouldProcess=$True)]
  Param ([Parameter(Mandatory=$true,Position=0)][string]$LogPath, 
         [Parameter(Mandatory=$true,Position=1)][string]$LogSum,
         [Parameter(Mandatory=$true,Position=2)][ValidateSet("Info","Warn","Error")][string]$LogLevel="Info",
         [Parameter(Mandatory=$false)][string]$LogDetail=$null,
         [Parameter(Mandatory=$false)][string]$SQLConnectionString="Server=$($MSEConfig.MSE_SQL_DBServer);Integrated Security=true;Initial Catalog=$($MSEConfig.MSE_SQL_DB)",
         [Parameter(Mandatory=$false)][bool]$Screen = $false,
         [Parameter(Mandatory=$false)][bool]$SQL = $false,
         [Parameter(Mandatory=$false)][bool]$EventLog = $false,
         [Parameter(Mandatory=$false)][string]$EventId = '0001'
  ) # End Param

  # Clean up variables and define in-house variables
  $FunctionName = "Write-MSELogFile"

  If (!(Test-Path -Path $LogPath)){
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
     (Add-Content -Path $LogPath -Value "In $($FunctionName): Started processing at [$([DateTime]::Now)].")
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
  }

  If (($LogSum -eq $null) -or ($LogSum -eq "")) {$LogSum = " - - - << No Logging Data Supplied >> - - - -"}
  $TempTimeStamp = Get-Date -format yyyyMMddHHmmss
  $LogSum = "$($TempTimeStamp) - $($LogSum)"

  # Write to local log file
  If ($LogDetail) {
     (Add-Content -Path $LogPath -Value $LogDetail)
  } else {
     (Add-Content -Path $LogPath -Value $LogSum)
  }

  # Write to screen if instructed
  If ($Screen){
     If ($LogDetail) {
        If (($LogLevel -eq "Warn") -or ($LogLevel -eq "Error") {
           Write-Warning $LogDetail
		} else {
           Write-Output $LogDetail
        }			
     } else {
        If (($LogLevel -eq "Warn") -or ($LogLevel -eq "Error") {
           Write-Warning $LogSum
		} else {
           Write-Output $LogSum
        }			
        Write-Output $LogSum
     }
  }
  
  # Write to EventLog if instructed
  If ($EventLog) {
     $EventLog   = "MSEAutomationEvents"
     $Source     = "TFSPSInfrastructure"
	 $DeviceID   = HOSTNAME
	  
	 If ($LogLevel -eq "Error") {
		 $EventLevel = "Error"
     } elseif ($LogLevel -eq "Warn") {
		 $EventLevel = "Warning"
     } else {
		 $EventLevel = "Information"
	 }
     Switch ($EventLevel){
        {$_ -match 'Error'}       {$id = New-Object System.Diagnostics.EventInstance($EventID,1,1)} #ERROR EVENT
        {$_ -match 'Warning'}     {$id = New-Object System.Diagnostics.EventInstance($EventID,1,2)} #WARNING EVENT
        {$_ -match 'Information'} {$id = New-Object System.Diagnostics.EventInstance($EventID,1)}   #INFORMATION EVENT
     }
	  
	 If ($LogDetail) {
		 $Message = $LogDetail
	 } else {
		 $Message = $LogSum
	 }
	  
     #Load the event source
     If ([System.Diagnostics.EventLog]::SourceExists($Source) -eq $false) {[System.Diagnostics.EventLog]::CreateEventSource($Source, $EventLog)}
 
     $Object = New-Object System.Diagnostics.EventLog;
     $Object.Log       = $EventLog;
     $Object.Source    = $Source;
     $Object.WriteEvent($id, @($Message))
  } 	  
  
  # Write to screen if instructed
  If ($SQL) {
	  $QueryString = @"
INSERT INTO [$($MSEConfig.MSE_SQL_DBServer)].[dbo].[$($MSEConfig.MSE_SQL_DB)](EventDate,EventEquipment,EventAccount,EventLevel,EventScript,EventType,EventDetail,EventShortDesc)
VALUES (GetDate(),$DeviceID,$env:username,$EventLevel,$($MyInvocation.MyCommand.Name),$EventID,$LogDetail,$LogSum)
"@  

dbo.MSEEventLog
SELECT TOP (1000) [EventId]
      ,[EventDate]
      ,[EventEquipment]
      ,[EventAccount]
      ,[EventLevel]
      ,[EventScript]
      ,[EventType]
      ,[EventDetail]
      ,[EventShortDesc]
  FROM [MSEAutomation].[dbo].[MSEEventLog]


	  Invoke-MSEDatabaseQuery $SQLconnectionString $query


  # Write to screen for debug mode
  If ($LogDetail) {
     Write-Debug $LogDetail
  } else {
     Write-Debug $LogSum
  }

  If ($ExitOnError) {
	 Write-Warning "CLosing down after error has been reported." 
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
     (Add-Content -Path $LogPath -Value "Closing down after error has been reported.")
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
     (Add-Content -Path $LogPath -Value "In $($FunctionName): Stopped processing at [$([DateTime]::Now)].")
     (Add-Content -Path $LogPath -Value "***************************************************************************************************")
	 

} # End function Write-MSELogFile
 


