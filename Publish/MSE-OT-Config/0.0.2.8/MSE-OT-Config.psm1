##################################################################################################################################################
##################################################################################################################################################

# We are going to define the default values for Machine and User. -RLG 5/4/2021
# Adding Global Values for the config functions since there were times that we were loosing scope within the module.

Add-Type -TypeDefinition @'
public interface IPsMetadataSerializable {
    string ToPsMetadata();
    void FromPsMetadata(string Metadata);
}
'@

#Defining Module Variables
$ModuleManifestExtension        = ".psd1"
$Global:MSEBinderIsSet          = $false
$Global:MSEScriptModule         = ""
$Global:MSEScriptName           = ""
$Global:MSEScriptCompanyName    = ""
$Global:MSEScriptDefaultPath    = ""

#Setting Default User Data Path 
$UserDataPath                   = $Env:LocalAppData
$UserDataPath                   = Join-Path $UserDataPath powershell
Write-Verbose "Header - UserDataPath: $UserDataPath"
#Setting Default Machine Data Path
$MachineDataPath                = $Env:ProgramData
$MachineDataPath                = Join-Path $MachineDataPath powershell
Write-Verbose "Header - MachineDataPath: $MachineDataPath"
##################################################################################################################################################



##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Public\ConvertFrom-MSEMetadata.ps1
##################################################################################################################################################
function ConvertFrom-MSEMetadata {
    <#
    .Synopsis
        Deserializes objects from PowerShell Data language (PSD1)
    .Description
        Converts psd1 notation to actual objects, and supports passing in additional converters
        in addition to using the built-in registered converters (see Add-MetadataConverter).

        NOTE: Any Converters that are passed in are temporarily added as though passed Add-MetadataConverter
    .Example
        ConvertFrom-MSEMetadata 'PSObject @{ Name = PSObject @{ First = "Joel"; Last = "Bennett" }; Id = 1; }'

        Id Name
        -- ----
        1 @{Last=Bennett; First=Joel}

        Convert the example string into a real PSObject using the built-in object serializer.
    .Example
        $data = ConvertFrom-MSEMetadata .\Configuration.psd1 -Ordered

        Convert a module manifest into a hashtable of properties for introspection, preserving the order in the file
    .Example
        ConvertFrom-MSEMetadata ("DateTimeOffset 635968680686066846 -05:00:00") -Converters @{
        "DateTimeOffset" = {
            param($ticks,$offset)
            [DateTimeOffset]::new( $ticks, $offset )
        }
        }

        Shows how to temporarily add a "ValidCommand" called "DateTimeOffset" to support extra data types in the metadata.

        See also the third example on ConvertTo-Metadata and Add-MetadataConverter
    #>
    [CmdletBinding()]
    param(
        # The metadata text (or a path to a metadata file)
        [Parameter(ValueFromPipelineByPropertyName = "True", Position = 0)]
        [Alias("PSPath")]
        $InputObject,

        # A hashtable of MetadataConverters (same as with Add-MetadataConverter)
        [Hashtable]$Converters = @{},

        # The PSScriptRoot which the metadata should be evaluated from.
        # You do not normally need to pass this, and it has no effect unless
        # you're referencing $PSScriptRoot or $ScriptRoot in your metadata
        $ScriptRoot = "$PSScriptRoot",

        # If set (and PowerShell version 4 or later) preserve the file order of configuration
        # This results in the output being an OrderedDictionary instead of Hashtable
        [Switch]$Ordered,

        # Allows extending the valid variables which are allowed to be referenced in metadata
        # BEWARE: This exposes the value of these variables in your context to the caller
        # You ware reponsible to only allow variables which you know are safe to share
        [String[]]$AllowedVariables
    )
    begin {
		Write-Verbose "#############################################"
		Write-Verbose "In ConvertFrom-MSEMetadata: in begin block"
        $OriginalMetadataSerializers = $Script:MetadataSerializers.Clone()
        $OriginalMetadataDeserializers = $Script:MetadataDeserializers.Clone()
        Add-MSEMetadataConverter $Converters
        [string[]]$ValidCommands = @(
            "ConvertFrom-StringData", "Join-Path", "Split-Path", "ConvertTo-SecureString"
        ) + @($MetadataDeserializers.Keys)
        [string[]]$ValidVariables = $AllowedVariables + @(
            "PSScriptRoot", "ScriptRoot", "PoshCodeModuleRoot", "PSCulture", "PSUICulture", "True", "False", "Null")
		Write-Verbose "In ConvertFrom-MSEMetaData: OriginalMetaDataSerializers"
		Write-Verbose ($OriginalMetaDataSerializers | Out-String)
		Write-Verbose "In ConvertFrom-MSEMetaData: OriginalMetaDataDeserializers"
		Write-Verbose ($OriginalMetaDataDeserializers | Out-String)
		Write-Verbose "In ConvertFrom-MSEMetaData: $ValidCommands"
		Write-Verbose "In ConvertFrom-MSEMetaData: $ValidVariables"
	
    }
    end {
		Write-Verbose "In ConvertFrom-MSEMetadata: in end block"
		$Script:MetadataSerializers = $OriginalMetadataSerializers.Clone()
        $Script:MetadataDeserializers = $OriginalMetadataDeserializers.Clone()
    }
    process {
		Write-Verbose "In ConvertFrom-MSEMetadata: in process block"
        $ErrorActionPreference = "Stop"
        $Tokens = $Null; $ParseErrors = $Null

		Write-Verbose "In ConvertFrom-MSEMetadata: Testing MSEPSVersion"
        if (Test-MSEPSVersion -lt "3.0") {
            # Write-Debug "$InputObject"
            if (!(Test-Path $InputObject -ErrorAction SilentlyContinue)) {
                $Path = [IO.path]::ChangeExtension([IO.Path]::GetTempFileName(), $ModuleManifestExtension)
                Set-Content -Encoding UTF8 -Path $Path $InputObject
                $InputObject = $Path
            } elseif (!"$InputObject".EndsWith($ModuleManifestExtension)) {
                $Path = [IO.path]::ChangeExtension([IO.Path]::GetTempFileName(), $ModuleManifestExtension)
                Copy-Item "$InputObject" "$Path"
                $InputObject = $Path
            }
            $Result = $null
            Import-LocalizedData -BindingVariable Result -BaseDirectory (Split-Path $InputObject) -FileName (Split-Path $InputObject -Leaf) -SupportedCommand $ValidCommands
            return $Result
        }
		
		Write-Verbose "In ConvertFrom-MSEMetaData: InputObject:"
		If ($InputObject) {Write-Verbose $InputObject}
		Write-Verbose "In ConvertFrom-MSEMetaData: Result:"
		If ($Result) {Write-Verbose $Result}
		Write-Verbose "In ConvertFrom-MSEMetadata: Testing Path before defining AST"
        if (Test-Path $InputObject -ErrorAction SilentlyContinue) {
            # ParseFile on PS5 (and older) doesn't handle utf8 encoding properly (treats it as ASCII)
            # Sometimes, that causes an avoidable error. So I'm avoiding it, if I can:
            $Path = Convert-Path $InputObject
            if (!$PSBoundParameters.ContainsKey('ScriptRoot')) {
                $ScriptRoot = Split-Path $Path
            }
            $Content = (Get-Content -Path $InputObject -Encoding UTF8)
            # Remove SIGnature blocks, PowerShell doesn't parse them in .psd1 and chokes on them here.
            $Content = $Content -join "`n" -replace "# SIG # Begin signature block(?s:.*)"
            try {
                # But older versions of PowerShell, this will throw a MethodException because the overload is missing
                $AST = [System.Management.Automation.Language.Parser]::ParseInput($Content, $Path, [ref]$Tokens, [ref]$ParseErrors)
            } catch [System.Management.Automation.MethodException] {
                $AST = [System.Management.Automation.Language.Parser]::ParseFile( $Path, [ref]$Tokens, [ref]$ParseErrors)

                # If we got parse errors on older versions of PowerShell, test to see if the error is just encoding
                if ($null -ne $ParseErrors -and $ParseErrors.Count -gt 0) {
                    $StillErrors = $null
                    $AST = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$Tokens, [ref]$StillErrors)
                    # If we didn't get errors, clear the errors
                    # Otherwise, we want to use the original errors with the path in them
                    if ($null -eq $StillErrors -or $StillErrors.Count -eq 0) {
                        $ParseErrors = $StillErrors
                    }
                }
            }
        } else {
            if (!$PSBoundParameters.ContainsKey('ScriptRoot')) {
                $ScriptRoot = $PoshCodeModuleRoot
            }

            $OFS = "`n"
            # Remove SIGnature blocks, PowerShell doesn't parse them in .psd1 and chokes on them here.
            $InputObject = "$InputObject" -replace "# SIG # Begin signature block(?s:.*)"
            $AST = [System.Management.Automation.Language.Parser]::ParseInput($InputObject, [ref]$Tokens, [ref]$ParseErrors)
        }
 
		Write-Verbose "In ConvertFrom-MSEMetadata: After PS5 Parse Check:"
		Write-Verbose "  : InputObject:"
		Write-Verbose $InputObject
		Write-Verbose "  : AST:"
		Write-Verbose $AST


		Write-Verbose "In ConvertFrom-MSEMetadata: Checking Errors from Path & Content Parsing"
        if ($null -ne $ParseErrors -and $ParseErrors.Count -gt 0) {
            ThrowError -Exception (New-Object System.Management.Automation.ParseException (, [System.Management.Automation.Language.ParseError[]]$ParseErrors)) -ErrorId "Metadata Error" -Category "ParserError" -TargetObject $InputObject
        }

		Write-Verbose "In ConvertFrom-MSEMetadata: Populating Tokens:"
        # Get the variables or subexpressions from strings which have them ("StringExpandable" vs "String") ...
        $Tokens += $Tokens | Where-Object { "StringExpandable" -eq $_.Kind } | Select-Object -ExpandProperty NestedTokens

		Write-Verbose "In ConvertFrom-MSEMetadata: Before Fixing ScriptRoot"
        # Work around PowerShell rules about magic variables
        # Replace "PSScriptRoot" magic variables with the non-reserved "ScriptRoot"
        if ($scriptroots = @($Tokens | Where-Object { ("Variable" -eq $_.Kind) -and ($_.Name -eq "PSScriptRoot") } | ForEach-Object { $_.Extent } )) {
			Write-Verbose "In ConvertFrom-MSEMetadata: In Fixing ScriptRoot"
            $ScriptContent = $Ast.ToString()
            for ($r = $scriptroots.count - 1; $r -ge 0; $r--) {
                $ScriptContent = $ScriptContent.Remove($scriptroots[$r].StartOffset, ($scriptroots[$r].EndOffset - $scriptroots[$r].StartOffset)).Insert($scriptroots[$r].StartOffset, '$ScriptRoot')
            }
            $AST = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$Tokens, [ref]$ParseErrors)
        }
		Write-Verbose "   : New AST Value:"
		Write-verbose $AST


        Write-Verbose "In ConvertFrom-MSEMetadata: Dumping AST into a ScriptBlock"
        $Script = $AST.GetScriptBlock()

#		Can't Print out a defined script block
#		Write-Verbose "In ConvertFrom-MSEMetadata: Script = AST.GetSCriptBlock()"
#		Write-Verbose $Script


        try {
            $Script.CheckRestrictedLanguage( $ValidCommands, $ValidVariables, $true )
        } catch {
			Write-Verbose "In ConvertFrom-MSEMetaData:  We're throwing an error"
            ThrowError -Exception $_.Exception.InnerException -ErrorId "Metadata Error" -Category "InvalidData" -TargetObject $Script
        }

		Write-Verbose "In ConvertFrom-MSEMetadata: Ordering HashTables"
        if ($Ordered -and (Test-MSEPSVersion -gt "3.0")) {
            # Make all the hashtables ordered, so that the output objects make more sense to humans...
            if ($Tokens | Where-Object { "AtCurly" -eq $_.Kind }) {
                $ScriptContent = $AST.ToString()
                $Hashtables = $AST.FindAll( {$args[0] -is [System.Management.Automation.Language.HashtableAst] -and ("ordered" -ne $args[0].Parent.Type.TypeName)}, $Recurse)
                $Hashtables = $Hashtables | ForEach-Object {
                    New-Object PSObject -Property @{Type = "([ordered]"; Position = $_.Extent.StartOffset}
                    New-Object PSObject -Property @{Type = ")"; Position = $_.Extent.EndOffset}
                } | Sort-Object Position -Descending
                foreach ($point in $Hashtables) {
                    $ScriptContent = $ScriptContent.Insert($point.Position, $point.Type)
                }
                $AST = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$Tokens, [ref]$ParseErrors)
                $Script = $AST.GetScriptBlock()
            }
        }

		Write-Verbose "In ConvertFrom-MSEMetadata: Outputing Mode:"
		If ($Mode) {
			Write-Verbose $Mode
		} Else {
			Write-Verbose "    No Mode available"
		}
		Write-Verbose "In ConvertFrom-MSEMetadata: Outputing ScriptContent:"
		If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
			If ($ScriptContent) {$ScriptContent}
		}
        $Mode, $ExecutionContext.SessionState.LanguageMode = $ExecutionContext.SessionState.LanguageMode, "RestrictedLanguage"

        try {
            $Script.InvokeReturnAsIs(@())
        } finally {
            $ExecutionContext.SessionState.LanguageMode = $Mode
        }
    }
}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Public\Get-MSEConfigurationPath.ps1
##################################################################################################################################################
function Get-MSEConfigurationPath {
    #.Synopsis
    #   Gets a storage path for configuration files and data
    #.Description
    #   Gets an AppData (or roaming profile) or ProgramData path for configuration and data storage. The folder returned is guaranteed to exist (which means calling this function actually creates folders).
    #
    #   Get-MSEConfigurationPath is designed to be called from inside a module function WITHOUT any parameters.
    #
    #   If you need to call Get-ConfigurationPath from outside a module, you should pipe the ModuleInfo to it, like:
    #   Get-Module Powerline | Get-MSEConfigurationPath
    #
    #   As a general rule, there are three scopes which result in three different root folders
    #       User:       $Env:LocalAppData
    #       Machine:    $Env:ProgramData
    #       Enterprise: $Env:AppData (which is the "roaming" folder of AppData)
    #
    #.NOTES
    #   1.  This command is primarily meant to be used in modules, to find a place where they can serialize data for storage.
    #   2.  It's techincally possible for more than one module to exist with the same name.
    #       The command uses the Author or Company as a distinguishing name.
    #
    #.Example
    #   $CacheFile = Join-Path (Get-MSEConfigurationPath) Data.clixml
    #   $Data | Export-CliXML -Path $CacheFile
    #
    #   This example shows how to use Get-MSEConfigurationPath with Export-CliXML to cache data as clixml from inside a module.
    [Alias("Get-MSEStoragePath")]
    # [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Callstack', Justification = 'This is referenced in ParameterBinder')]
    # [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Module', Justification = 'This is referenced in ParameterBinder')]
    [CmdletBinding(DefaultParameterSetName = '__ModuleInfo')]
    param(
        # The scope to save at, defaults to Enterprise (which returns a path in "RoamingData")
#        We aren't going to even entertian Enterprise
#        [ValidateSet("User", "Machine", "Enterprise")]
        [ValidateSet("User", "Machine")]
		# RLG - 20210423 - Changed default to machine to fit our purposes.
	#	[string]$Scope = "Enterprise",
		[string]$Scope = "Machine",

        # A callstack. You should not ever pass this.
        # It is used to calculate the defaults for all the other parameters.
        [Parameter(ParameterSetName = "__CallStack")]
        [System.Management.Automation.CallStackFrame[]]$CallStack = $(Get-PSCallStack),

        # The Module you're importing configuration for
        [Parameter(ParameterSetName = "__ModuleInfo", ValueFromPipeline = $true)]
        [System.Management.Automation.PSModuleInfo]$Module,

        # An optional module qualifier (by default, this is blank)
        [Parameter(ParameterSetName = "ManualOverride", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Author")]
        [String]$CompanyName,

        # The name of the module or script
        # Will be used in the returned storage path
        [Parameter(ParameterSetName = "ManualOverride", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Name,

        # The version for saved settings -- if set, will be used in the returned path
        # NOTE: this is *NOT* calculated from the CallStack
        [Version]$Version,

        # By default, Get-ConfigurationPath creates the folder if it doesn't already exist
        # This switch allows overriding that behavior: if set, does not create missing paths
        [Switch]$SkipCreatingFolder
    )
    begin {
        $PathRoot = $(switch ($Scope) {
                "User" {
                    $UserDataPath
                }
                "Machine" {
                    $MachineDataPath
                }
                default {
                    $MachineDataPath
                }
            })
        if (Test-Path $PathRoot) {
            $PathRoot = Resolve-Path $PathRoot
        } elseif (!$SkipCreatingFolder) {
            Write-Warning "The $Scope path $PathRoot cannot be found"
        }
    }

    process {
		If (($MSEBinderIsSet) -and (!$Module)){
			$Module = $Global:MSEScriptModule
		}
		write-verbose "In Get-MSEConfigurationPath: Module:"
		If ($Module) {write-verbose $Module}
		write-verbose "In Export-MSEConfiguration: GlobalModule:"
		If ($Global:Module) {write-verbose $Global:Module}
        If (!$MSEBinderIsSet){
			If ((!$Module) -and ($Global:MSEScriptModule)) {
				$Module = $Global:MSEScriptModule
			}
			. MSEParameterBinder
		}

		Write-Verbose "In Get-MSEConfigurationPath: Module"
		Write-Verbose $Module
		Write-Verbose "In Get-MSEConfigurationPath: Checking on path"
		Write-Verbose ((Get-Module $Module).Path)
		Write-Verbose (Test-Path (Join-Path (Split-Path ((Get-Module $Module).Path)) "Configuration.psd1"))
		
		If (Test-Path (Join-Path (Split-Path ((Get-Module $Module).Path)) "Configuration.psd1")){
			# We'll just assume that we have the correct configuration file and continue.
		}else{
			If ((get-childitem -path (Split-Path ((Get-Module $Module).Path)) -Filter "Configuration.*.psd1").count -gt 0){
				$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				If ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
					If (!(Set-DefaultConfigFile)){ 
						Write-Output "A Default configuration could not be set.  Please check the MSEAutomation Module installation and then:"
						Write-Output ""
						Write-Output "Please open a PowerShell Script with Elevated (Administrator) privileges and tune th following commands".
						Write-Output "     Import-Module MSEAutomation; Get-Module MSEAutomation | Set-DefaultConfigFile"
						pause
						exit
					}	
				}else{
					Write-Output "A Default configuration has not yet been selected."
					Write-Output ""
					Write-Output "Please open a PowerShell Script with Elevated (Administrator) privileges and tune th following commands".
					Write-Output "     Import-Module MSEAutomation; Get-Module MSEAutomation | Set-DefaultConfigFile"
					pause
					exit
				}
			}else{
				Write-Output "No Default or Template configuration files were found.   Please reinstall the MSEAutomation module."
				pause
				exit
			}
		}
		
        if (!$Name) {
			If ($Module) {
				$Name = $Module.Name
			} Else {
				Write-Error "Empty Name ($Name) in $($PSCmdlet.ParameterSetName): $($PSBoundParameters | Format-List | Out-String)"
				throw "Could not determine the storage name, Get-ConfigurationPath should only be called from inside a script or module."
			}
        }

        if (!$CompanyName) {
			If ($Module) {
				$CompanyName = $Module.CompanyName
			}
		}
		$CompanyName = $CompanyName -replace "[$([Regex]::Escape(-join[IO.Path]::GetInvalidFileNameChars()))]", "_"
        if ($CompanyName -and $CompanyName -ne "Unknown") {
            $PathRoot = Join-Path $PathRoot $CompanyName
        }

        $PathRoot = Join-Path $PathRoot $Name

# Future Feature
#        if ($Version) {
#            $PathRoot = Join-Path $PathRoot $Version
#        }

        if (Test-Path $PathRoot -PathType Leaf) {
            throw "Cannot create folder for Configuration because there's a file in the way at $PathRoot"
        }

        if (!$SkipCreatingFolder -and !(Test-Path $PathRoot -PathType Container)) {
            $null = New-Item $PathRoot -Type Directory -Force
        }

        # Note: this used to call Resolve-Path
        return $PathRoot
    }
}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Public\Import-MSEConfiguration.ps1
##################################################################################################################################################
function Import-MSEConfiguration {
    #.Synopsis
    #   Import the full, layered configuration for the module.
    #.Description
    #   Imports the DefaultPath Configuration file, and then imports the Machine, and local user config files, if they exist.
    #   Each configuration file is layered on top of the one before (so only needs to set values which are different)
    #.Example
    #   $Configuration = Import-Configuration
    #
    #   This example shows how to use Import-Configuration in your module to load the cached data
    #
    #.Example (Our preferred methodology)
    #   $Configuration = Get-Module Configuration | Import-Configuration
    #
    #   This example shows how to use Import-Configuration in your module to load data cached for another module
    #
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Callstack', Justification = 'This is referenced in MSEParameterBinder')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Module', Justification = 'This is referenced in MSEParameterBinder')]
    # [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DefaultPath', Justification = 'This is referenced in ParameterBinder')]
    [CmdletBinding(DefaultParameterSetName = '__CallStack')]
    param(
        # The Module you're importing configuration for
        [Parameter(ParameterSetName = "__ModuleInfo", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.PSModuleInfo]$Module,

        # An optional module qualifier (by default, this is blank)
        [Parameter(ParameterSetName = "Default", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Author")]
        [String]$CompanyName,

        # The name of the module or script
        # Will be used in the returned storage path
        [Parameter(ParameterSetName = "Default", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Name,

        # The full path (including file name) of a default Configuration.psd1 file
        # By default, this is expected to be in the same folder as your module manifest, or adjacent to your script file
        [Parameter(ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [Alias("ModuleBase")]
        [String]$DefaultPath,

		# Future Functionality
        # The version for saved settings -- if set, will be used in the returned path
        # NOTE: this is *never* calculated, if you use version numbers, you must manage them on your own
        # [Version]$Version,

        # If set (and PowerShell version 4 or later) preserve the file order of configuration
        # This results in the output being an OrderedDictionary instead of Hashtable
        [Switch]$Ordered
    )
    begin {
        # Write-Debug "Import-Configuration for module $Name"
		Write-Verbose "Import-Configuration: Entered Function Call"
    }
    process {
		If (!($Name -and $CompanyName -and $DefaultPath)) {
			write-verbose "In Import-MSEConfiguration: Module:"
			If ($Module) {write-verbose $Module}
			write-verbose "In Import-MSEConfiguration: GlobalModule:"
			If ($Global:Module) {write-verbose $Global:Module}
			If (!$MSEBinderIsSet){
				If ((!$Module) -and ($Global:MSEScriptModule)) {
					$Module = $Global:MSEScriptModule
				}	
				. MSEParameterBinder
			}
		}

		$TempModuleName = $Module.Name
		write-verbose "From ParameterBinder: Module        :$TempModuleName"
		write-verbose "From ParameterBinder: CompanyName   :$CompanyName"
		write-verbose "From ParameterBinder: Name          :$Name"
		write-verbose "From ParameterBinder: DefaultPath   :$DefaultPath"

        if (!$Name) {
            throw "Could not determine the configuration name. When you are not calling Import-Configuration from a module, you must specify the -CompanyName and -Name parameter"
        }

        if ($DefaultPath -and (Test-Path $DefaultPath -PathType Container)) {
            $DefaultPath = Join-Path $DefaultPath Configuration.psd1
			Write-verbose "From Import-MSEConfiguration: Default Path again: $DefaultPath"
        }

		Write-verbose "From Import-MSEConfiguration: Collecting Default Configuration"
        $Configuration = if ($DefaultPath -and (Test-Path $DefaultPath)) {
            Import-MSEMetadata $DefaultPath -Ordered:$Ordered
        } else {
            @{}
        }
		If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
			If ($Configuration) {
				$Configuration
			}
		}

        # Write-Debug "Module Configuration: ($DefaultPath)`n$($Configuration | Out-String)"
        $Parameters = @{
            CompanyName = $CompanyName
            Name        = $Name
        }
        if ($Version) {
            $Parameters.Version = $Version
        }
		Write-verbose "From Import-MSEConfiguration: Parameters:"
		If ($Parameters){
			Write-Verbose "  Name        : $($Parameters.Name)"
			Write-Verbose "  CompanyName : $($Parameters.CompanyName)"
		}

		# This is where we will check to see if there is a Machine Scope to add to the configuration.
		If ($MachineDataPath) {Write-Verbose "In Import-MSEConfiguration: MachineDataPath: $MachineDataPath"}
		If ((!$MachineDataPath) -or ((Split-Path $MachineDataPath -leaf) -eq 'powershell')) {
			Write-Verbose "In Import-MSECOnfiguration: Getting MachineDataPath"
			$MachineDataPath = Get-MSEConfigurationPath @Parameters -Scope Machine -SkipCreatingFolder
		}
        $MachineDataPath = Join-Path $MachineDataPath Configuration.psd1
        if (Test-Path $MachineDataPath) {
            $MachineData = Import-MSEMetadata $MachineDataPath -Ordered:$Ordered
            # At some point need to compe back and figure out why -ErrorAction was causing an error itself
            # Import-MSEMetadata $MachinePath -ErrorAction Ignore -Ordered:$Ordered
			write-verbose "From Import-MSEConfiguration: MachineDataPath: $MachineDataPath"
			write-verbose "From Import-MSEConfiguration: Machine metadata:"
			If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
				$MachineData
			}
        } else {
            Write-Verbose "In Import-MSEConfiguration: Machine Configuration file not found."
        }

		If ($UserDataPath) {Write-Verbose "In Import-MSEConfiguration: UserDataPath: $UserDataPath"}
		If ((!$UserDataPath) -or ((Split-Path $UserDataPath -Leaf) -eq 'powershell')) {
			Write-Verbose "In Import-MSECOnfiguration: Getting MachineDataPath"
			$UserDataPath = Get-MSEConfigurationPath @Parameters -Scope Machine -SkipCreatingFolder
		}
        $UserDataPath = Join-Path $UserDataPath Configuration.psd1
		if (Test-Path $UserDataPath) {
            $UserData = Import-MSEMetadata $UserDataPath -ErrorAction Ignore -Ordered:$Ordered
			write-verbose "From Import-MSEConfiguration: LocalUserPath: $UserDataPath"
			write-verbose "From Import-MSEConfiguration: LocalUser metadata:"
			If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
				$UserData
			}
        } else {
            Write-Verbose "In Import-MSEConfiguration: LocalUser Configuration file not found."
        }



		write-verbose "From Import-MSEConfiguration: Default Configuration"
		If (($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) -and ($Configuration)) {
			$Configuration
		}
		If ($MachineData) {
			$Configuration = MSEMergeHashTables $Configuration $MachineData
			write-verbose "From Import-MSEConfiguration: Default & Machine Configuration"
			If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
				$Configuration
			}
		}
		If ($UserData) {
			$Configuration = MSEMergeHashTables $Configuration $UserData
			write-verbose "From Import-MSEConfiguration: Default & Machine & LocalUser Configuration"
			If ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
				$Configuration
			}
		}
    }
}



##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Public\Import-MSEMetadata.ps1
##################################################################################################################################################
function Import-MSEMetadata {
    <#
      .Synopsis
         Creates a data object from the items in a Metadata file (e.g. a .psd1)
      .Description
         Serves as a wrapper for ConvertFrom-Metadata to explicitly support importing from files
      .Example
         $data = Import-MSEMetadata .\Configuration.psd1 -Ordered

         Convert a module manifest into a hashtable of properties for introspection, preserving the order in the file
   #>
    [CmdletBinding()]
    param(
        # The path to the metadata (.psd1) file to import
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath", "Content")]
        [string]$Path,

        # A hashtable of MetadataConverters (same as with Add-MetadataConverter)
        [Hashtable]$Converters = @{},

        # If set (and PowerShell version 4 or later) preserve the file order of configuration
        # This results in the output being an OrderedDictionary instead of Hashtable
        [Switch]$Ordered

    )
    process {
        if (Test-Path $Path) {
            # Write-Debug "Importing Metadata file from `$Path: $Path"
            Write-Verbose "In Import-MSEMetadata: Importing Metadata file from `$Path: $Path"
            if (!(Test-Path $Path -PathType Leaf)) {
                $Path = Join-Path $Path ((Split-Path $Path -Leaf) + $ModuleManifestExtension)
            }
        }
        if (!(Test-Path $Path)) {
            MSEWriteError -ExceptionType System.Management.Automation.ItemNotFoundException `
                -Message "Can't find file $Path" `
                -ErrorId "PathNotFound,Metadata\Import-Metadata" `
                -Category "ObjectNotFound"
            return
        }
        try {
			Write-Verbose "In Import-MSEMetadata: - calling ConvertFrom-MSEMetadata"
			Write-Verbose "In Import-MSEMetadata: Path: $Path"
#			Write-Verbose "In Import-MSEMetadata: Converters: "
#			Write-Verbose ($Converters|Out-String)
#			Write-Verbose "In Import-MSEMetadata: Ordered:"
#			Write-Verbose $Ordered
#			Write-Verbose "In Import-MSEMetadata: AllowedVariables" 
#			If ($AllowedVariables) {Write-Verbose $AllowedVariables}
			
            ConvertFrom-MSEMetadata -InputObject $Path -Converters $Converters -Ordered:$Ordered -AllowedVariables $AllowedVariables
        } catch {
            MSEThrowError $_
        }
    }
}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Public\Test-MSEPSVersion.ps1
##################################################################################################################################################
function Test-MSEPSVersion {
    <#
      .Synopsis
         Test the PowerShell Version
      .Description
         This function exists so I can do things differently on older versions of PowerShell.
         But the reason I test in a function is that I can mock the Version to test the alternative code.
      .Example
         if(Test-MSEPSVersion -ge 3.0) {
            ls | where Length -gt 12mb
         } else {
            ls | Where { $_.Length -gt 12mb }
         }

         This is just a trivial example to show the usage (you wouldn't really bother for a where-object call)
   #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Version]$Version = $PSVersionTable.PSVersion,
        [Version]$lt,
        [Version]$le,
        [Version]$gt,
        [Version]$ge,
        [Version]$eq,
        [Version]$ne
    )

    $all = @(
        if ($lt) { $Version -lt $lt }
        if ($gt) { $Version -gt $gt }
        if ($le) { $Version -le $le }
        if ($ge) { $Version -ge $ge }
        if ($eq) { $Version -eq $eq }
        if ($ne) { $Version -ne $ne }
    )

    $all -notcontains $false
}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Private\MSEMergeHashTables.ps1
##################################################################################################################################################
<#MSEMergeHashTables.ps1

Quick write.   The internal function for the original Configuration Module was not working the way I liked.
It produced duplicates of some keys ... which doesn't work well in a hash table.  -RLG  4/28/2021

#>
function MSEMergeHashTables($htold, $htnew)
{
	#Start with a clone of our base hashtable
    $MyBaseht = $htold.clone()
	#We want everything in htnew to either overwrite or add to the existing hashtable.
	#Existing items in htnew will stay undisturbed.
	$htnew.keys | ForEach-Object {$MyBaseht[$_] = $htnew[$_]}
	return $MyBaseht



#  Code below was first attempt.   Did not work as expected.
#    $keys = $htold.getenumerator() | foreach-object {$_.key}
#    $keys | foreach-object {
#        $key = $_
#        if ($htnew.containskey($key))
#        {
#            $htold.remove($key)
#        }
#    }
#    $htnew = $htold + $htnew
#    return $htnew
}

##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Private\MSEParameterBinder.ps1
##################################################################################################################################################
function MSEParameterBinder {
	write-verbose "In ParameterBinder: Setting Module Value"
	if ($Module) {write-verbose $Module}
    if (!$Module) {
		if ($Global:MSEScriptModule) {
			$Module = $Global:MSEScriptModule
			write-verbose "In ParameterBinder: Module Set to Global Value"
		} Else {
			[System.Management.Automation.PSModuleInfo]$Module = . {
#       	 [System.Management.Automation.PSModuleInfo]$BinderModule = . {
				$Command = ($CallStack)[0].InvocationInfo.MyCommand
				$mi = if ($Command.ScriptBlock -and $Command.ScriptBlock.Module) {
					$Command.ScriptBlock.Module
				} else {
					$Command.Module
				}

				if ($mi -and $mi.ExportedCommands.Count -eq 0) {
					if ($mi2 = Get-Module $mi.ModuleBase -ListAvailable | Where-Object { ($_.Name -eq $mi.Name) -and $_.ExportedCommands } | Select-Object -First 1) {
						$mi = $mi2
					}
				}
				$mi
				write-verbose "In ParameterBinder: Module Set to calculated value"
			}
        }
    }
	write-verbose "In ParameterBinder: Setting Company Name:"
    if (!$CompanyName -or ($CompanyName -eq "AnonymousModules")) {
        If ($Global:MSEScriptCompanyName) {
			$CompanyName = $Global:MSEScriptCompanyName
			write-verbose "In ParameterBinder: CompanyName Set to Global Value"
		} Else {
			if ($null -ne ($Module.CompanyName)) {
				$CName = $Module.CompanyName -replace "[$([Regex]::Escape(-join[IO.Path]::GetInvalidFileNameChars()))]", "_"
				if (($CName -eq "Unknown") -or ($null -eq $CName)) {
					$CName = $Module.Author
					if (($CName -eq "Unknown") -or ($null -eq $CName)) {
						$CName = "AnonymousModules"
					}
				}
				$CompanyName = $CName
				write-verbose "In ParameterBinder: CompanyName Set to calculated value"
			} else {
				$CompanyName = "AnonymousScripts"
				write-verbose "In ParameterBinder: CompanyName Set to AnonymousScripts"
			}
		}
    }

	write-verbose "In ParameterBinder: Setting Name: "
    if (!$Name) {
		If ($Global:MSEScriptName) {
			$Name = $Global:MSEScriptName
			write-verbose "In ParameterBinder: Name Set to Global Value"
		} Else {
			[String]$Name = $(if ($Module) {
				$Module.Name
            } <# else { ($CallStack)[0].InvocationInfo.MyCommand.Name } #>)
			write-verbose "In ParameterBinder: Name Set to calculated value"
		}
    }

	write-verbose "In ParameterBinder: Setting DefaultPath:"
	if (!$DefaultPath) {
		If ($Global:MSEScriptDefaultPath) {
			$DefaultPath = $Global:MSEScriptDefaultPath
		} Else {
			if ($Module) {
				[String]$DefaultPath = Join-Path $Module.ModuleBase "Configuration.psd1"
			}
		}
	}

write-verbose "In ParameterBinder: Module:"
write-verbose $Module
write-verbose "In ParameterBinder: Name: "
write-verbose $Name
write-verbose "In ParameterBinder: Company Name:"
write-Verbose $CompanyName
write-verbose "In ParameterBinder: DefaultPath:"
write-verbose $DefaultPath

If (($Module) -and ($Name) -and ($CompanyName) -and ($DefaultPath)) {$Script:MSEBinderIsSet = $true}
If (($Module) -and (!$Global:MSEScriptModule)) {$Global:MSEScriptModule = $Module}
If (($CompanyName) -and (!$Global:MSEScriptCompanyName)) {$Global:MSEScriptCompanyName = $CompanyName}
If (($DefaultPath) -and (!$Global:MSEScriptDefaultPath)) {$Global:MSEScriptDefaultPath = $DefaultPath}
If (($Name) -and (!$Global:MSEScriptName)) {$Global:MSEScriptName = $Name}

}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Private\MSEThrowError.ps1
##################################################################################################################################################
# Utility to throw an errorrecord
function MSEThrowError {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidOverwritingBuiltInCmdlets", "")]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $((Get-Variable -Scope 1 PSCmdlet).Value),

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "NewException")]
        [ValidateNotNullOrEmpty()]
        [System.Exception]
        $Exception,

        [Parameter(ParameterSetName = "NewException", Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionType = "System.Management.Automation.RuntimeException",

        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $false)]
        [System.Object]
        $TargetObject,

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 10)]
        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 10)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 11)]
        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 11)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $Category,

        [Parameter(Mandatory = $true, ParameterSetName = "Rethrow", Position = 1)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    process {
        if (!$ErrorRecord) {
            if ($PSCmdlet.ParameterSetName -eq "NewException") {
                if ($Exception) {
                    $Exception = New-Object $ExceptionType $Message, $Exception
                } else {
                    $Exception = New-Object $ExceptionType $Message
                }
            }
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorId, $Category, $TargetObject
        }
        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}


##################################################################################################################################################
# Sourced from file named:
#       .\MSE-OT-Config\Source\Private\MSEWriteError.ps1
##################################################################################################################################################
# Utility to throw an errorrecord
function MSEWriteError {
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $((Get-Variable -Scope 1 PSCmdlet).Value),

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "NewException")]
        [ValidateNotNullOrEmpty()]
        [System.Exception]
        $Exception,

        [Parameter(ParameterSetName = "NewException", Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionType = "System.Management.Automation.RuntimeException",

        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $false)]
        [System.Object]
        $TargetObject,

        [Parameter(Mandatory = $true, Position = 10)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory = $true, Position = 11)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $Category,

        [Parameter(Mandatory = $true, ParameterSetName = "Rethrow", Position = 1)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    process {
        if (!$ErrorRecord) {
            if ($PSCmdlet.ParameterSetName -eq "NewException") {
                if ($Exception) {
                    $Exception = New-Object $ExceptionType $Message, $Exception
                } else {
                    $Exception = New-Object $ExceptionType $Message
                }
            }
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorId, $Category, $TargetObject
        }
        $Cmdlet.WriteError($errorRecord)
    }
}
$MetadataSerializers = @{}
$MetadataDeserializers = @{}
 


