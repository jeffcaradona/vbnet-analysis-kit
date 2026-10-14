---
name: vbnet-analysis
description: 'Inspect VB.NET declarations and invocation syntax using a local Roslyn tool. Use to outline classes/modules/methods/properties, inspect a selected declaration, or investigate possible calls in VB.NET, including legacy report tracing. Distinguish syntax candidates from resolved references. Not for SQL parsing, C# analysis, compilation, or semantic reference resolution.'
---

# VB.NET syntax analysis

## Select the workflow

**Standalone:** locate candidate `.vb` files with `rg` or `fd`, then use the installed launcher described in [commands](references/commands.md). It runs offline after installation.

**Modernization Evidence Harness investigation:** use server-exposed tools, approved repository aliases, and evidence returned by the harness. If a Roslyn MCP operation exists, follow its actual schema. If absent, use existing search/excerpt tools and identify Roslyn integration as pending. The proposal shipped with this kit does not install or register an MCP tool.

Do not silently substitute local terminal analysis for harness collection. Supplementary standalone observations must be explicitly requested and labeled uncataloged; they cannot satisfy artifact references.

## Standalone procedure

1. Locate selected files; do not parse an entire repository by default.
2. Invoke `scripts/Invoke-VbAnalysis.ps1` through PowerShell 7, beginning with `outline`.
3. Select the exact declaration start line for `inspect` or `calls`.
4. Inspect `analysis`, `parseErrorCount`, `truncated`, `textTruncated`, and `limitations` before drawing conclusions.
5. Report paths and 1-based ranges. Use bounded text search and source reads for follow-up evidence.

The current outline has no pagination. If it truncates, state the gap and use bounded text discovery; do not claim all declarations were examined. Pagination is proposed for harness integration, not implemented here.

## Interpretation boundaries

An invocation expression is syntax evidence, not a resolved method call. It can be array/default-property access, includes invocations inside nested lambdas, and excludes bare member access and object creation. No solution, reference assemblies, or semantic model are loaded. Conditional branches reflect default parser symbols, not necessarily the project's build configuration.

The current tool does not extract argument mappings, assignments, SQL relationships, or complete report execution paths. Mark those as follow-up evidence needs. Parse failures and unsupported encodings must remain visible.

## Installation

The user runs the kit installer, which builds and smoke-tests the parser before installing customizations. If the launcher or parser is missing, report that fact; do not improvise an alternative parser or claim an invocation succeeded.
