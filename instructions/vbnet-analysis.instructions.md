---
applyTo: "**/*.vb"
description: "Use bounded local Roslyn analysis for VB.NET; preserve the evidence boundary when working through the Modernization Evidence Harness."
---

# VB.NET analysis

Load `~/.copilot/skills/vbnet-analysis/SKILL.md` for VB.NET declaration structure, bounded declaration inspection, or invocation-expression inspection.

## Choose the execution path

- For standalone source exploration, use the skill's installed local Roslyn launcher. First locate candidate files with `rg` or `fd`.
- For an investigation governed by the Modernization Evidence Harness, use its available MCP tools and repository aliases. Use Roslyn through that server only when the integration is actually implemented and exposed. Do not invent an `analyze_vb_source` tool.
- If the server does not expose Roslyn analysis, continue with its existing inventory, search, and excerpt tools and report the missing capability. Do not bypass the server with direct filesystem analysis and present the result as harness evidence.
- If the user explicitly requests supplementary standalone analysis, label it as uncataloged working-tree observations. It has no harness evidence ID, snapshot guarantee, or manifest validation status.

## Interpret results honestly

- Start with `outline`; use its returned declaration start line for `inspect` or `calls`.
- The current tool is syntax-only. Invocation syntax can represent array/default-property access. Do not call it a resolved symbol, confirmed caller, complete call graph, or proof of runtime behavior.
- Report parse errors, truncation, and relevant preprocessor/encoding limitations. A missing result is not proof of absence when coverage is incomplete.
- Cite paths and 1-based source ranges. A harness claim must use evidence IDs actually returned by that harness; never manufacture IDs or approval status.
- Use text search for SQL embedded in VB strings. This parser does not resolve SQL definitions, dynamic SQL, reflection, or project dependencies.
- Do not build or execute inspected repositories, modify source, or install dependencies during analysis. If the standalone tool is missing, report it and refer the user to the kit installer.
- Keep outputs bounded; read small source ranges only when structured observations do not answer the question.
