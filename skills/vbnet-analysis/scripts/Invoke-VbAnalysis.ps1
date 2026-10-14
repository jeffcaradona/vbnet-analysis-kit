#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('outline','inspect','calls')][string]$Command,
    [Parameter(Mandatory)][string]$File,
    [ValidateRange(1,2147483647)][int]$Line,
    [ValidateRange(1,100)][int]$Limit = 50,
    [ValidateRange(1,12000)][int]$MaxChars = 4000
)
$ErrorActionPreference = 'Stop'
$copilotRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$dll = Join-Path $copilotRoot 'tools/vbnet-analysis/0.1.0/VbAnalysis.dll'
if (!(Test-Path -LiteralPath $dll)) { throw 'VB.NET analysis tool is missing. Run Install.ps1 from the kit.' }
$resolved = (Resolve-Path -LiteralPath $File).Path
$toolArgs = @($dll, $Command, $resolved, '--limit', "$Limit", '--max-chars', "$MaxChars")
if ($PSBoundParameters.ContainsKey('Line')) { $toolArgs += @('--line', "$Line") }
& dotnet @toolArgs
# Preserve native exit status in $LASTEXITCODE without exiting the user's shell.
