# Commands and output

Run in PowerShell 7. Default installation:

```powershell
$vbTool = Join-Path $HOME '.copilot/skills/vbnet-analysis/scripts/Invoke-VbAnalysis.ps1'
& $vbTool -Command outline -File './Reports/ReportRunner.vb' -Limit 30
# Replace 42 with the declaration startLine returned by outline.
& $vbTool -Command inspect -File './Reports/ReportRunner.vb' -Line 42 -MaxChars 4000
& $vbTool -Command calls -File './Reports/ReportRunner.vb' -Line 42 -Limit 30
```

Output is one compact JSON object: schema/tool version, command, file, analysis,
total, returned, truncated, parseErrorCount, diagnostics (first ten), limitations,
and results. Paths are absolute with forward slashes; convert them to
repository-relative paths before citing them. Ranges are 1-based;
end positions are exclusive. `inspect` may truncate text mid-line and marks it.

Exit codes: 0 parsed successfully; 2 syntax errors (partial evidence emitted);
1 invalid arguments, invalid selection, decoding, or other operational error
(JSON error on stderr). Check `$LASTEXITCODE` immediately after invocation.

`outline` lists namespaces, classes/modules/structures/interfaces, enums,
methods, constructors, properties, events, and delegates. It does not list
fields, local variables, accessors, operators, or imports in this release.
`calls` requires a method/constructor block, not an interface signature.
Select declarations by exact start line to avoid ambiguous overloaded names.

Limits: single `.vb` file, 5 MiB input, maximum 100 results (default 50),
maximum 12,000 inspection characters (default 4,000), 200-character names or
call expressions. There is no pagination; when truncated, use text search to
narrow the investigation rather than claiming completeness.

Parsing uses Roslyn 4.14.0, default language/preprocessor options, UTF-8 or
BOM-detected UTF-16/UTF-32. Legacy ANSI files without a BOM are not supported;
make an explicitly encoded temporary copy if needed, preserving original source.
Record the conversion and cite the original path, as described in report-tracing.md, section 1.
Default preprocessor symbols may exclude branches used by the actual project.
No project build settings, references, or semantic model are loaded.
