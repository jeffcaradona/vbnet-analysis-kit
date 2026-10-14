---
applyTo: "**/*.vb"
description: "When investigating VB.NET code, use the vbnet-analysis skill and preserve the Modernization Evidence Harness evidence boundary."
---

# VB.NET analysis

These rules apply when investigating or explaining VB.NET code, including tracing legacy reports. They do not restrict editing VB.NET files when the user asks for changes.

Load `~/.copilot/skills/vbnet-analysis/SKILL.md` for the procedure. For report questions, follow its report-tracing reference, including the coverage ledger and answer format.

## Evidence boundary

- In a Modernization Evidence Harness investigation, use its MCP tools and repository aliases. Do not invent an `analyze_vb_source` tool or any other tool the server does not expose.
- Do not bypass the server with direct filesystem analysis and present the result as harness evidence. Standalone analysis requires an explicit user request and is labeled uncataloged: it has no harness evidence ID, snapshot guarantee, or manifest validation status.
- Cite evidence IDs only when the harness actually returned them. Never manufacture IDs or approval status.

## Honest results

- Syntax observations are candidates, not resolved symbols, confirmed callers, complete call graphs, or proof of runtime behavior.
- A missing result is not proof of absence when coverage is incomplete. Report parse errors, truncation, result caps, and encoding limits.
- While investigating, do not build or execute the inspected repositories, modify their source, or install dependencies. If the standalone tool is missing, say so and refer the user to the kit installer.
