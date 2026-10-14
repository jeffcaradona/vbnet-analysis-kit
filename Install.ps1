#Requires -Version 7.0
[CmdletBinding()]
param([string]$CopilotRoot = 'C:\Users\jeffc\.copilot')
$ErrorActionPreference = 'Stop'
Get-Command dotnet -ErrorAction Stop | Out-Null
$runtimes = & dotnet --list-runtimes
if ($LASTEXITCODE -ne 0 -or !($runtimes -match '^Microsoft.NETCore.App 8\.')) {
    throw 'Install the .NET 8 SDK/runtime first. This tool targets net8.0.'
}
$instruction = Join-Path $CopilotRoot 'instructions/vbnet-analysis.instructions.md'
$skill = Join-Path $CopilotRoot 'skills/vbnet-analysis'
$tool = Join-Path $CopilotRoot 'tools/vbnet-analysis/0.1.0'
foreach ($destination in @($instruction, $skill, $tool)) {
    if (Test-Path -LiteralPath $destination) { throw "Destination already exists; no overwrite performed: $destination" }
}
$stage = Join-Path ([IO.Path]::GetTempPath()) ('vbnet-analysis-' + [guid]::NewGuid().ToString('N'))
try {
    $project = Join-Path $PSScriptRoot 'src/VbAnalysis/VbAnalysis.csproj'
    & dotnet publish $project -c Release --self-contained false -o $stage --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Build failed; Copilot files were not installed.' }
    & (Join-Path $PSScriptRoot 'tests/Smoke-Test.ps1') -Dll (Join-Path $stage 'VbAnalysis.dll')
    New-Item -ItemType Directory -Force -Path (Split-Path $instruction), (Split-Path $skill), $tool | Out-Null
    Copy-Item -Path (Join-Path $stage '*') -Destination $tool -Recurse
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'skills/vbnet-analysis') -Destination $skill -Recurse
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'instructions/vbnet-analysis.instructions.md') -Destination $instruction
    Write-Host "Installed instructions: $instruction"
    Write-Host "Installed skill: $skill"
    Write-Host 'Start a new Copilot session and verify the skill/instructions in Agent Customizations.'
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
