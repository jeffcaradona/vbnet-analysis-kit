# VB.NET analysis kit — 0.1.0

A read-only Roslyn CLI with a Copilot skill and a narrowly scoped instruction file.
Default instruction destination: `C:\Users\jeffc\.copilot\instructions\vbnet-analysis.instructions.md`.

## Install

Prerequisites: Windows, PowerShell 7, .NET 8 SDK (including its runtime), and NuGet
access for the initial package restore. Analysis runs locally/offline after install.

Extract this ZIP into a normal working folder. Open PowerShell 7 in that folder:

```powershell
.\Install.ps1
```

The installer builds the included source, runs the included smoke tests, then
copies the published runtime files, skill and instructions into `.copilot`.
It refuses to overwrite existing destinations. It does not modify
`local-tools.instructions.md`, your existing codebase-search skill, PATH, or
VS Code profiles. It does not build or execute the repository being inspected.
If PowerShell blocks a downloaded script, inspect it and use your normal trusted
script process; the installer does not change execution policy.

Installed paths:

- `instructions/vbnet-analysis.instructions.md`
- `skills/vbnet-analysis/` (workflow, recipes, launcher)
- `tools/vbnet-analysis/0.1.0/` (published DLL and dependencies)

Start a new Copilot session. Verify both the skill and instructions appear in
Agent Customizations. Automatic discovery depends on your VS Code/Copilot
version and session harness; filesystem placement alone is not a discovery test.
The instruction file applies to `**/*.vb`; the skill description also supports
VB.NET investigation requests before any source file is attached.

## First use

```powershell
$vbTool = 'C:/Users/jeffc/.copilot/skills/vbnet-analysis/scripts/Invoke-VbAnalysis.ps1'
& $vbTool -Command outline -File 'C:/path/to/ReportRunner.vb'
```

Use a returned declaration startLine for `inspect` or `calls`, as documented in
`skills/vbnet-analysis/references/commands.md`. No global `roslyn` executable is
assumed. Errors are JSON on stderr. Results are compact JSON on stdout.

## Scope and limits

Syntax only: no project loading, symbol resolution, semantic references, SQL
parsing or code modification. Invocation expressions are candidates, not proven
method calls. Includes parse diagnostics, explicit truncation and source ranges.
Default conditional-compilation symbols may differ from the actual project.
UTF-8 or BOM-encoded Unicode input; legacy ANSI must be handled explicitly.

.NET 8 / Roslyn 4.14.0 are deliberately pinned as a baseline, not claimed to be
the latest versions. The wrapper is C# code analyzing VB.NET source.

## Validation status

Source and package layout reviewed; project XML and ZIP contents checked in the
generation environment. Compilation and runtime tests were NOT executed there:
the .NET SDK and PowerShell were unavailable. The installer runs the smoke tests
locally before copying Copilot customizations. Treat this as a source kit pending
that local build, not a prevalidated binary release.

Smoke tests cover declaration discovery, exclusion of fake calls in comments
and strings, bounded source output, and result truncation.

## Remove

Remove only the three installed paths above. Keep unrelated `.copilot` contents.
Retain this source kit for future versioned changes.

## References

- https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/get-started/syntax-analysis
- https://www.nuget.org/packages/Microsoft.CodeAnalysis.VisualBasic/4.14.0
- https://code.visualstudio.com/docs/agent-customization/migrate-customizations
