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
