---
applyTo: "**/*.vb"
description: "Use local Roslyn syntax analysis for VB.NET declarations and call expressions."
---

# VB.NET analysis with local Roslyn

For VB.NET structure, load `~/.copilot/skills/vbnet-analysis/SKILL.md`.
Use `rg` to select candidate files, then the skill's installed Roslyn launcher for declarations, bounded source inspection, or invocation expressions. Return file paths and line ranges as evidence.

- Do not assume installation succeeded: if the launcher or tool is missing, report it and ask the user to run the package installer. Do not install dependencies or create an alternative parser during an investigation.
- Start with `outline`; use its declaration start line for `inspect` or `calls`.
- This tool performs **syntax analysis only**. An invocation expression is not a confirmed method call, reference, overload, caller, or runtime dependency. Array and default-property access can have the same syntax.
- Report parse errors, truncation, and relevant conditional-compilation limitations. Never interpret incomplete output as an exhaustive finding.
- Do not load solutions, build the investigated repository, modify source, or execute the inspected code for these operations.
- Use ordinary text search for SQL embedded in VB strings. Roslyn does not resolve stored-procedure definitions or dynamically generated SQL.
- Read small source ranges only when structured output cannot answer the question. Keep output bounded.
