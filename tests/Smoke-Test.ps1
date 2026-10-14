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

# Syntax errors: exit 2 with partial results and diagnostics on stdout.
$raw = & dotnet $Dll outline (Join-Path $PSScriptRoot 'ParseError.vb')
if ($LASTEXITCODE -ne 2) { throw "Expected exit code 2 for syntax errors; got $LASTEXITCODE." }
$partial = $raw | ConvertFrom-Json
if ($partial.parseErrorCount -lt 1 -or @($partial.diagnostics).Count -lt 1 -or @($partial.results).Count -lt 1) {
    throw 'Expected partial outline results with parse diagnostics.'
}

$work = Join-Path ([IO.Path]::GetTempPath()) ('vbnet-analysis-smoke-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    # Invalid BOM-less UTF-8 (a lone Windows-1252 0xE9 byte): exit 1 with a JSON error on stderr.
    $invalid = Join-Path $work 'Invalid.vb'
    $bytes = [Text.Encoding]::ASCII.GetBytes("Public Module M`n    ' caf") + [byte[]](0xE9) + [Text.Encoding]::ASCII.GetBytes("`nEnd Module`n")
    [IO.File]::WriteAllBytes($invalid, $bytes)
    $stderrFile = Join-Path $work 'stderr.txt'
    # Native stderr redirection must not be promoted to a terminating error.
    $ErrorActionPreference = 'Continue'
    $raw = & dotnet $Dll outline $invalid 2> $stderrFile
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($code -ne 1) { throw "Expected exit code 1 for invalid UTF-8; got $code." }
    if ($raw) { throw 'Expected no stdout for invalid UTF-8.' }
    $failure = Get-Content -LiteralPath $stderrFile -Raw | ConvertFrom-Json
    if (!$failure.error) { throw 'Expected a JSON error on stderr for invalid UTF-8.' }

    # Supported BOM-encoded input, including non-ASCII text, parses cleanly.
    # Build non-ASCII text from code points so this script's own encoding does not matter.
    $moduleName = 'Caf' + [char]0x00E9
    $source = "Public Module $moduleName`n    Public Sub Run()`n        Dim label As String = `"na$([char]0x00EF)ve`"`n    End Sub`nEnd Module`n"
    $encodings = @{
        'Utf8Bom.vb'  = [Text.UTF8Encoding]::new($true)
        'Utf16Bom.vb' = [Text.UnicodeEncoding]::new($false, $true)
    }
    foreach ($name in $encodings.Keys) {
        $path = Join-Path $work $name
        [IO.File]::WriteAllText($path, $source, $encodings[$name])
        $raw = & dotnet $Dll outline $path
        if ($LASTEXITCODE -ne 0) { throw "Expected $name to parse; got exit code $LASTEXITCODE." }
        $bom = $raw | ConvertFrom-Json
        if ($bom.parseErrorCount -ne 0 -or @($bom.results | Where-Object name -eq $moduleName).Count -ne 1) {
            throw "Expected $name to outline module $moduleName without parse errors."
        }
    }
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Smoke tests passed.'
