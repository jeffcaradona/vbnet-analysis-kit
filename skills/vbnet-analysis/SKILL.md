---
name: vbnet-analysis
description: 'Inspect VB.NET declarations and invocation syntax using a local Roslyn tool, and trace legacy reports across one or more repositories. Use to outline classes/modules/methods/properties, inspect a selected declaration, investigate possible calls, or answer which files generate a legacy report. Distinguish syntax candidates from resolved references. Not for SQL parsing, C# analysis, compilation, or semantic reference resolution.'
---

# VB.NET syntax analysis

## Select the workflow

**Report questions** ("which files generate report X", "where does this report get its data"): follow [report tracing](references/report-tracing.md) in either mode below. It defines the search order, coverage ledger and required answer format.

**Standalone:** locate candidate `.vb` files with `rg` (or `fd`; if absent, `rg --files -g "*.vb"`), then use the installed launcher described in [commands](references/commands.md). It runs offline after installation.

**Modernization Evidence Harness investigation:** use server-exposed tools, approved repository aliases, and evidence returned by the harness. If a Roslyn MCP operation exists, follow its actual schema. If absent, use existing search/excerpt tools and identify Roslyn integration as pending. The proposal shipped with this kit does not install or register an MCP tool.

Do not silently substitute local terminal analysis for harness collection. Supplementary standalone observations must be explicitly requested and labeled uncataloged; they cannot satisfy artifact references.

Upstream harness `baa4158` has known search-cap and late-line read defects. Check whether the downstream harness still has them, and treat a capped search or a failed range read as a coverage gap, not proof of absence. See report tracing, section 3.

## Standalone procedure

1. Record each repository's commit as context, and the content identity of each cited file (report tracing, section 1).
2. Locate selected files; do not parse an entire repository by default.
3. Invoke `scripts/Invoke-VbAnalysis.ps1` through PowerShell 7, beginning with `outline`.
4. Select the exact declaration start line for `inspect` or `calls`.
5. Inspect `analysis`, `parseErrorCount`, `truncated`, `textTruncated`, and `limitations` before drawing conclusions. A truncated `inspect` did not show the whole declaration.
6. Report repository-relative paths and 1-based ranges. Use bounded text search and source reads for follow-up evidence.

The current outline has no pagination. If it truncates, state the gap and use bounded text discovery; do not claim all declarations were examined. Pagination is proposed for harness integration, not implemented here.

## Interpretation boundaries

An invocation expression is syntax evidence, not a resolved method call. It can be array/default-property access, includes invocations inside nested lambdas, and excludes bare member access and object creation. No solution, reference assemblies, or semantic model are loaded. Conditional branches reflect default parser symbols, not necessarily the project's build configuration.

The current tool does not extract object creation, argument mappings, assignments, SQL relationships, or complete report execution paths. Find those with text search, label them lexical, and keep the relationships they suggest as candidates until separate evidence confirms them. Never merge same-named declarations across files or repositories into one target.

Parse failures and unsupported encodings must remain visible. If a file is analyzed through a re-encoded temporary copy, follow the re-encoding rules in report tracing, section 1: cite the original path, never the temporary one. For non-ASCII search text in Windows-1252 files, use `rg -E windows-1252`.

## Installation

The user runs the kit installer, which builds and smoke-tests the parser before installing customizations. If the launcher or parser is missing, report that fact; do not improvise an alternative parser or claim an invocation succeeded.
