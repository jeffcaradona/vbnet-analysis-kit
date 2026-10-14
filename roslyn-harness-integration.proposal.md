# Proposal: Roslyn syntax evidence in the downstream Modernization Evidence Harness

Status: proposed; no downstream changes made
Date: 2026-10-14
Audience: downstream harness maintainers
Scope: read-only VB.NET evidence collection through the existing MCP server

## Decision requested

Approve a small Roslyn adapter behind the existing Node.js MCP server. Reuse the standalone parser as a starting point, and make the harness own source selection, snapshot identity, execution limits, redaction, evidence recording, and artifact validation.

Keep personal Copilot instructions and skills as a separate delivery surface. They guide tool usage but do not enforce evidence integrity. The standalone kit is useful for local exploration; it must not become an alternative evidence path that bypasses the harness.

## Problem and intended outcome

Investigations span up to 15 approved repositories to explain how legacy reports work: entry points, parameter construction, helper calls, query selection, data access, and output behavior. Fixed-string search efficiently finds candidates, but the model must currently infer much of the surrounding code structure from excerpts.

Roslyn can deterministically identify declarations and invocation expressions and return their source spans. This reduces manual source interpretation without claiming that syntax proves resolved calls, runtime behavior, or business correctness. The model chooses investigative questions and explains findings; tools establish reproducible observations.

The initial outcome is narrow: find a report identifier with existing search, inspect its enclosing VB.NET structure through MCP, and cite cataloged syntax observations alongside direct excerpts.

## Grounding and downstream reconciliation

This proposal is based on the public upstream at commit `baa4158bbc09b0d7143d1b006bc6b0607e3baa88`, not inspection of the private downstream fork.

Observed upstream:

- `src/server.js` exposes inventory, fixed-string search, bounded source excerpts, and artifact-reference validation.
- `src/config.js` accepts an arbitrary nonempty repository-alias map; the server derives allowed aliases from it. The README describes two example repositories, but the tool schema is not hard-coded to two.
- `src/repositories/repository-service.js` pins revisions and checks drift/cleanliness around collection.
- `src/evidence/evidence.js` records repository alias, commit, relative path, line range, analysis method, source hash, excerpt, and truncation/redaction metadata.
- `src/session/evidence-catalog.js` is in-memory. Reference validation depends on cataloged evidence.
- `src/subprocess/runner.js` provides no-shell execution and output/time limits; stdin is currently ignored.
- Existing validation distinguishes reference integrity, semantic correctness, and department approval.

Before implementation, map these responsibilities to their downstream equivalents and identify what already exists, especially durable state, multi-repository orchestration, and additional report-tracing tools. Preserve downstream contracts; do not replace working implementations merely to match upstream paths.

## Milestones

| Stage | Scope | Exit criterion |
|---|---|---|
| Existing harness Milestone 1 | Controlled collection, snapshots, evidence IDs, reference validation | Preserve its guarantees and regression tests |
| Roslyn integration MVP | One file, syntax only; outline, declaration inspection, invocation expressions | MCP returns bounded, attributable syntax evidence from the pinned source |
| Report-tracing increment | Add arguments/assignments and other needed observations against synthetic report fixtures | One representative report path explained with supported links and explicit gaps |
| Expansion toward 15 repositories | Durable investigations, selective traversal, coverage reporting, measured caching | A teammate can resume and verify the same investigation across recorded snapshots |

These are proposed increments, not claims that the public upstream or current kit implements them.

## Component boundary

The parser is a versioned .NET executable invoked by the Node server using an argument array with `shell: false`. A PowerShell launcher remains optional for personal/manual use; the server must not depend on personal shell profiles or a specific user's home directory.

| Parser owns | Harness owns |
|---|---|
| Parsing supplied VB source | Approved aliases, paths, and source selection |
| Syntax extraction and source spans | Commit/blob identity and decoding policy |
| Parser options and diagnostic reporting | Timeouts, cancellation, input/output limits |
| Stable structured observations | Redaction, evidence IDs, persistence, validation |

Do not introduce a second MCP server for the MVP. Keep the parser independent of Git, repository configuration, artifact manifests, and model providers.

## Proposed interface

Proposed MCP tool name: `analyze_vb_source`. The name is not a currently available tool.

Inputs: approved `repositoryAlias`, normalized `relativePath`, an operation enum (`outline`, `inspect`, `invocations`), optional declaration selection, and bounded pagination/limit fields. The server owns the pinned revision and effective parser configuration; callers do not supply arbitrary executable paths, root paths, or compiler arguments.

Internal parser protocol: one bounded JSON request on stdin, one JSON response on stdout, diagnostics on stderr. The request carries schema version, operation, logical source path, exact decoded source text, selection, effective parser options, and limits. The response carries schema version, parser/extractor versions, effective options, diagnostics, coverage/truncation, and structured observations with spans.

The existing standalone command `calls` may map to internal `invocations`; document that mapping explicitly and preserve standalone compatibility.

## Source and evidence integrity

1. Validate alias/path and sensitive-file policy before reading source.
2. Prefer reading committed blob bytes at the session's pinned revision. Decode under a recorded encoding policy; retain blob identity and a hash of the exact parser input. Do not parse a bounded excerpt as if it were a complete file.
3. Pass source to the parser through bounded stdin. Extend the subprocess runner to write the request, handle stream errors, close stdin, and enforce cancellation/time/output limits.
4. Validate response schema, versions, operation, spans, result counts and byte limits. Reject malformed or byte-truncated JSON. Treat parse-error output as explicitly partial evidence, not a clean success.
5. Extract citation snippets from the same source snapshot. Parse the original source locally; redact all returned source-bearing fields before exposing them to Copilot, including expressions, names where necessary, and diagnostics. Do not parse redacted code and call it the original structure.
6. Convert observations into the existing evidence contract and record them before returning them.

Add an analysis classification such as `Syntax observation`. Record operation, parser/extractor version, effective language/preprocessor options, and parse diagnostics as provenance. Define a versioned identity scheme or analysis fingerprint so different extraction rules/options cannot silently reuse an identity for different findings. Exclude timings and timestamps from deterministic identity.

Normalize ranges deliberately: the kit uses 1-based positions with exclusive ends, while the harness excerpt contract uses line ranges. Test conversion at line endings and empty spans. Keep UTF-16 character offsets explicit if retained from Roslyn.

A matching method name in two files does not establish a cross-repository call edge. Invocation syntax can denote array/default-property access. Reference integrity remains separate from resolved-symbol correctness and business interpretation.

## Changes to the standalone kit

- Split CLI handling from a reusable `VbSyntaxAnalyzer` and operation-specific extractors.
- Add explicit request/response types and JSON-over-stdin mode while preserving file-based manual commands.
- Add paging or targeted selection so declarations beyond the first result cap are reachable. Bind continuation state to input hash, operation and parser options; reject stale continuation.
- Emit stable ordering, effective options, diagnostic completeness, and per-field truncation. Never silently truncate declaration identity fields used for selection.
- Keep standalone installation separate from harness deployment. A downstream config resolves a trusted versioned executable; personal installation under `.copilot` is not required on team machines.

The delivered 0.1.0 source kit has not been compiled in the generation environment. Its user-run installer builds and executes smoke tests. Compilation, runtime validation, and downstream adaptation are prerequisites for accepting this proposal's MVP.

## Multi-repository operation

Treat an investigation as a manifest of repository aliases and their individual pinned commits, not one implied global revision. Record dependency/version assumptions between repositories; arbitrary HEAD snapshots need not represent a mutually compatible deployed system.

Search selectively, then follow evidenced references. Record which repositories were searched, not searched, excluded, failed, or truncated. Do not interpret an unsearched repository as having no relevant code. Return bounded batches instead of dumping 15 repositories into context.

For resumable team use, persist the snapshot manifest, evidence records, analysis provenance, and artifact-reference manifest. Reload and validate that state after a server restart. Adopt any existing downstream implementation rather than adding a duplicate catalog.

Add parsing caches only after measuring repeated work. Cache keys must include source content, parser/extractor versions and options; evidence records must still retain distinct repository identities even when identical bytes reuse a parse result.

## Validation and acceptance

Use synthetic fixtures only; private source is not required in upstream tests.

MVP tests must demonstrate:

- Build and actual parser execution on the supported Windows/.NET environment.
- Identical source/options/version yield identical normalized observations and evidence identity; telemetry may vary.
- Comments and string literals containing call-like text are not invocations.
- Multiline declarations/calls have correct ranges; duplicate names and overloads remain distinguishable.
- Array/default-property syntax is not promoted to a confirmed method call.
- Conditional-compilation options, parse errors, unsupported encodings and output truncation remain visible.
- Results beyond the first page are reachable; stale continuation is rejected.
- Source drift, unapproved aliases/paths, malformed output, missing parser, timeout and cancellation produce explicit failures.
- Redaction covers parser fields and diagnostics without corrupting the local parse input.
- Different repositories with identical paths preserve distinct evidence identity.
- The reference validator accepts genuinely cataloged syntax evidence and rejects fabricated/stale references under its existing contract.

For the report-tracing increment, create a small multi-repository fixture with an entry point, parameter construction, shared helper, configuration/query selection, and SQL artifact. Include a duplicate method name, a misleading comment, and an unresolved dynamic target. The expected explanation must preserve that unresolved target rather than invent a complete path.

Measure against the current lexical/excerpt baseline: supported findings, false relationship claims, unresolved links, tool calls, returned bytes, and elapsed time. Do not use explanation fluency as the acceptance metric. Test larger repository counts and practical corpus sizes before claiming 15-repository scalability.

## Deferred work

Full solution loading, semantic binding, overload resolution, complete call graphs, dynamic SQL evaluation, runtime tracing, automatic modernization, model inference, vector databases, and additional agents are outside this MVP. Add them only for demonstrated unanswered questions.

## Rollout

1. Reconcile this proposal against the downstream fork and agree on contracts.
2. Build/test the parser independently with synthetic sources.
3. Add an optional adapter and MCP tool; preserve existing tools and artifact behavior.
4. Run the synthetic report investigation and compare against baseline.
5. Pilot selected real reports locally; retain explicit coverage and unresolved links.
6. Expand scope after evidence quality and measured performance pass review.

## References

- Public baseline: https://github.com/jeffcaradona/modernization-evidence-harness/tree/baa4158bbc09b0d7143d1b006bc6b0607e3baa88
- Architecture: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/architecture.md
- Evidence contract: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/evidence-and-artifacts.md
- Adding tools: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/adding-a-tool.md
