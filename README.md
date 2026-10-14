# VB.NET analysis kit — 0.1.0

A read-only Roslyn CLI with a Copilot skill and a narrowly scoped instruction file.
Default instruction destination: `$HOME/.copilot/instructions/vbnet-analysis.instructions.md`.

## Deliverables

| Delivery | Repository path | Destination / use |
|---|---|---|
| Personal instructions | [vbnet-analysis.instructions.md](instructions/vbnet-analysis.instructions.md) | `~/.copilot/instructions/` |
| Personal skill | [vbnet-analysis](skills/vbnet-analysis/SKILL.md) and its companion files | `~/.copilot/skills/vbnet-analysis/` |
| Downstream integration proposal | [roslyn-harness-integration.proposal.md](roslyn-harness-integration.proposal.md) | Review in the downstream Modernization Evidence Harness fork |

The personal workflow uses the existing standalone parser. The proposal specifies
future MCP integration; it does not add a server or implement new parser commands.
For harness-governed investigations, use actual server tools and cataloged
evidence. Standalone output must not be represented as harness evidence.

## Install

Prerequisites: Windows, PowerShell 7, .NET 8 SDK (including its runtime), and NuGet
access for the initial package restore. Analysis runs locally/offline after install.

Clone this repository (or extract its ZIP). Open PowerShell 7 in the repository root:

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

## Update an existing personal installation

The installer deliberately refuses existing destinations. If the parser is already
installed and you are applying only these instructions/skill updates, back up and
replace or add the Markdown files below from the repository. Keep the existing
launcher and published tool:

- `instructions/vbnet-analysis.instructions.md` → `$HOME/.copilot/instructions/vbnet-analysis.instructions.md`
- `skills/vbnet-analysis/SKILL.md` → `$HOME/.copilot/skills/vbnet-analysis/SKILL.md`
- `skills/vbnet-analysis/references/commands.md` → `$HOME/.copilot/skills/vbnet-analysis/references/commands.md`
- `skills/vbnet-analysis/references/report-tracing.md` → `$HOME/.copilot/skills/vbnet-analysis/references/report-tracing.md` (new)

Review any personal edits before replacement. The proposal stays in this repository;
do not install it as an automatically loaded instruction file. Start a new session
and verify discovery. For a different home directory, pass `-CopilotRoot` to the
installer and adjust the example paths accordingly.

## First use

```powershell
$vbTool = Join-Path $HOME '.copilot/skills/vbnet-analysis/scripts/Invoke-VbAnalysis.ps1'
& $vbTool -Command outline -File 'C:/path/to/ReportRunner.vb'
```

Use a returned declaration startLine for `inspect` or `calls`, as documented in
`skills/vbnet-analysis/references/commands.md`. For "which files generate report X" questions, the skill follows
`skills/vbnet-analysis/references/report-tracing.md`: a fixed search order, a
per-repository coverage ledger and a required answer format. No global `roslyn` executable is
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
and strings, bounded source output, result truncation, exit code 2 with partial
JSON and diagnostics on syntax errors, exit code 1 with a JSON error for invalid
BOM-less UTF-8, and successful parsing of UTF-8 and UTF-16 input with a BOM.
The parser tests need only .NET and PowerShell 7; Windows-specific behavior still
needs validation on Windows.

## Remove

Remove only the three installed paths above. Keep unrelated `.copilot` contents.
Retain this source kit for future versioned changes.

## References

- https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/get-started/syntax-analysis
- https://www.nuget.org/packages/Microsoft.CodeAnalysis.VisualBasic/4.14.0
- https://code.visualstudio.com/docs/agent-customization/migrate-customizations
