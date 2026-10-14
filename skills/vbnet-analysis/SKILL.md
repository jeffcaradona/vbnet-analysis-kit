---
name: vbnet-analysis
description: 'Inspect VB.NET source structure locally using Roslyn. Use for outlining classes, modules, methods and properties; inspecting a selected declaration; or listing invocation expressions within a Sub, Function or constructor. Also use when investigating VB.NET callers to distinguish syntax candidates from resolved references. Not for C#, SQL parsing, formatting, compilation, or semantic reference resolution.'
---

# VB.NET syntax analysis

1. Find candidate `.vb` files with `rg` or `fd`; do not scan a whole repository with Roslyn.
2. Read [command recipes](references/commands.md).
3. Invoke `scripts/Invoke-VbAnalysis.ps1` through PowerShell 7. It calls the published local tool without restore or build.
4. Use `outline`, then select a declaration start line for `inspect` or `calls`.
5. Read `analysis`, `parseErrorCount`, `truncated`, `textTruncated`, and `limitations` before drawing conclusions. Report paths and 1-based source ranges.
6. Use bounded `rg` and source reads for follow-up evidence.

The tool has no model, API calls, or network dependencies at runtime. It does not execute inspected source or load project files. A successful result proves syntax was observed, not semantic identity.

`calls` lists invocation syntax, which may be array/default-property access. It includes nested lambdas, excludes bare member accesses and constructors invoked with `New`, and cannot resolve overloads, late binding, reflection, or runtime dispatch. Do not call it a complete call graph.

Installation is user-run from the accompanying kit. If missing, stop tool execution and report the missing installation; do not claim the tool ran or silently switch to an improvised Roslyn implementation.
