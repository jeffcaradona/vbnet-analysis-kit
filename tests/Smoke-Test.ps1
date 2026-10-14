#Requires -Version 7.0
param([Parameter(Mandatory)][string]$Dll)
$ErrorActionPreference = 'Stop'
$fixture = Join-Path $PSScriptRoot 'Sample.vb'
$raw = & dotnet $Dll outline $fixture
if ($LASTEXITCODE -ne 0) { throw 'Outline failed.' }
$outline = $raw | ConvertFrom-Json
$run = @($outline.results | Where-Object name -eq 'Run')
if ($run.Count -ne 1 -or $outline.parseErrorCount -ne 0) { throw 'Expected one Run method and no parse errors.' }
$raw = & dotnet $Dll calls $fixture --line $run[0].range.startLine
if ($LASTEXITCODE -ne 0) { throw 'Calls failed.' }
$calls = $raw | ConvertFrom-Json
if ($calls.total -ne 2 -or $calls.analysis -ne 'syntax-only') { throw 'Expected exactly two syntax invocations (not comment/string text).' }
$raw = & dotnet $Dll inspect $fixture --line $run[0].range.startLine --max-chars 10
if ($LASTEXITCODE -ne 0) { throw 'Inspect failed.' }
$inspect = $raw | ConvertFrom-Json
if (!$inspect.results[0].textTruncated -or $inspect.results[0].text.Length -ne 10) { throw 'Inspection bound failed.' }
$raw = & dotnet $Dll outline $fixture --limit 1
if ($LASTEXITCODE -ne 0) { throw 'Bounded outline failed.' }
$limited = $raw | ConvertFrom-Json
if (!$limited.truncated -or $limited.returned -ne 1) { throw 'Result limit failed.' }
Write-Host 'Smoke tests passed.'
