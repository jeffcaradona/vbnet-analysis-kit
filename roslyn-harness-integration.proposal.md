# Proposal: Roslyn syntax evidence in the downstream Modernization Evidence Harness

Status: proposed, revised after review; no downstream changes made
Date: 2026-10-14
Audience: downstream harness maintainers
Scope: read-only legacy report tracing through VB.NET syntax and report-artifact evidence

## Decision requested

Approve a small Roslyn adapter behind the existing Node.js MCP server. Reuse the standalone parser as a starting point, and make the harness own source selection, snapshot identity, execution limits, redaction, evidence recording, and artifact validation.

Keep personal Copilot instructions and skills as a separate delivery surface in this repository. Do not ship them as required components of the downstream harness. They guide tool usage but do not enforce evidence integrity. The standalone kit is useful for local exploration; it must not become an alternative evidence path that bypasses the harness.

## Problem and intended outcome

Investigations span up to 15 approved repositories to explain how legacy reports work: entry points, parameter construction, helper calls, query selection, data access, and output behavior. Fixed-string search efficiently finds candidates, but the model must currently infer much of the surrounding code structure from excerpts.

Roslyn can deterministically identify declarations and invocation expressions and return their source spans. This reduces manual source interpretation without claiming that syntax proves resolved calls, runtime behavior, or business correctness. The model chooses investigative questions and explains findings; tools establish reproducible observations.

The initial useful outcome is report-centered: given a report identifier, identify candidate entry points, report classes/files, procedure names, and parameter expressions across approved repositories; return typed relationships with citations and unresolved targets. An outline and invocation list alone is a parser prototype, not this report-tracing MVP.

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

## Review disposition and prerequisite fixes

The review correctly identifies that the first proposal prioritized general syntax operations over the relationships needed to answer “which files generate report X.” Move the report-relevant extractors and artifact observations into the MVP. The source kit remains a prototype and does not gain those capabilities merely because this proposal names them.

The late-excerpt and silent-search-cap failures were independently reproduced against upstream `baa4158` with synthetic committed files on 2026-10-14:

- 601 matching lines yielded 20 evidence items, no top-level completeness flag, and no item marked truncated.
- Search found a procedure name at line 1803. Reading from line 1802 failed with `E_LINE_RANGE_INVALID`: the reader had sliced a 16 KiB prefix before selecting lines. The reported prefix line count varies with fixture line length; it is not the full file's line count.
- The Windows command-line limit is a code-inspection risk, not a reproduced Windows failure.
- UTF-8 assumptions and the in-memory catalog are established by source inspection.

Land and validate the following downstream prerequisites before accepting or enabling the Roslyn MCP integration. Independent parser prototyping need not stop, but it must not obscure these release gates.

| Prerequisite | Required behavior |
|---|---|
| Snapshot-based range reads | Read the requested lines from the pinned blob, then bound the returned excerpt. Stream to the range or decode the full file within a separate supported input limit; never mistake a prefix for the full file. If the source exceeds a processing limit, report that limit explicitly. |
| Honest search coverage | Return scope, scanned/skipped/failed files, page/return limits, and completeness. Provide a file-oriented result mode for “which files” questions so one file's matching lines cannot consume all visible coverage. |
| Counts with known meaning | Distinguish matching files, matching lines, and occurrences. Report an exact total only after scanning the entire declared scope; otherwise return an observed lower bound and `totalKnown: false`. A cap or timeout must not silently imply absence. |
| Windows-safe search execution | Do not place every committed path in one command line. Implement bounded argument batches with deterministic aggregation, or search an immutable approved snapshot staging area. Preserve tracked-only/sensitive-path policy, pagination and coverage across batches. |
| Encoding support | Support configured Windows-1252 as well as strict UTF-8 and BOM-declared Unicode. Use one decoding policy for search, excerpts, XML and Roslyn input, with applicable XML declarations handled explicitly. Preserve original blob hashes and record the effective decoding/transcoding choice. |
| Durable investigations | Persist snapshots, evidence and analysis provenance; restart/reload and revalidate manifests without inventing past catalog entries. Reuse the downstream solution if already present. |

Do not implement the path-list fix as `filenames | rg ...`: ripgrep searches stdin as content. Its `-f` option reads patterns, not filenames. Do not assume an unverified `--files-from` option exists. Bounded batches or controlled snapshot staging are concrete alternatives. If stdin is used to search one blob's contents, the harness must supply and retain that blob's identity separately.

Windows-1252 is an explicit supported policy, not a universal “ANSI” detector or silent fallback for corrupt UTF-8. Specify precedence (BOM, applicable XML declaration, configured file/repository encoding, default), reject conflicts/invalid data, and test non-ASCII literals and offsets.

## Milestones

| Stage | Scope | Exit criterion |
|---|---|---|
| Existing harness Milestone 1 | Controlled collection, snapshots, evidence IDs, reference validation | Preserve its guarantees and regression tests |
| Prerequisite milestone | Snapshot range reads, search coverage/count semantics, Windows-safe execution, encoding and durable investigations | Late-file evidence is accessible, incomplete searches are visible, and evidence survives restart |
| Report-tracing MVP | VB report relationships, structural XML artifact inspection, bounded declaration candidate index | One representative report's participating files and procedure references are supported by evidence, with ambiguous/unresolved relationships retained |
| Expansion toward 15 repositories | Broader fixture coverage, selective traversal, measured caching and workload limits | A teammate can resume and verify the investigation across recorded snapshots with explicit coverage |

These are proposed increments, not claims that the upstream or current kit implements them. The MVP has several extractors but stays bounded to named report-tracing observations; it does not require a general-purpose semantic call graph.

## Report relationships required in the MVP

| Source construct | Observation returned | Claim boundary |
|---|---|---|
| `New rptMonthEnd()` | Object-creation type syntax, arguments, containing declaration and span | Type-name candidate; no resolved constructor/type claim |
| `ReportDocument.Load("MonthEnd.rpt")` | Receiver/member syntax and positional/named argument expressions; exact literal value when present | A literal load argument, not proof the file exists or executes |
| `ReportPath = "...rdlc"` | Assignment target, right-hand expression/literal and scope | Syntactic resource reference; resolve actual artifact candidates separately |
| `cmd.CommandText = "usp_MonthEndSales"` | Member assignment, literal procedure candidate and receiver syntax | Record separately from `CommandType`; co-occurrence alone does not prove the same runtime command state |
| `With cmd ... .CommandText = ...` | Nearest enclosing `With` receiver expression, nesting and assignment spans | Receiver syntax, not semantic identity or evaluated value |
| `Handles btnPrint.Click` | Method's event-handler clause and source locations | Declared handler association; no proof of the UI execution path |
| `Parameters.AddWithValue("@StartDate", value)` | Receiver/member, positional/named arguments, literal parameter name and value expression | No runtime value or proven procedure-parameter binding |

Record expressions that cannot be reduced under supported deterministic rules as unresolved. Do not execute VB, evaluate arbitrary expressions, or guess concatenated/dynamic paths. Version any limited literal/constant extraction rules.

Return typed relationship observations with provenance for each endpoint/expression. Preserve observed syntax separately from candidate resolution. Argument extraction is syntactic positional/named argument mapping, not binding arguments to a resolved method signature.

## Report artifacts beyond VB.NET

Add an artifact-specific service behind the same harness evidence boundary. It can use a separate XML parser; Roslyn does not need to parse XML report formats.

| Artifact | MVP treatment |
|---|---|
| `.rdlc` / `.rdl` | Namespace-aware XML extraction of datasets, command text/type, report parameters and supported resource references; retain expression text when dynamic |
| Typed `.xsd` datasets | Inspect supported TableAdapter command/procedure and parameter metadata; report unsupported schema variants |
| `.vbproj` | Observe literal Compile/EmbeddedResource items, links and conditions. Do not execute MSBuild or treat unevaluated items/globs/imports as complete build membership |
| `.config` / `.resx` | Extract supported report-path/resource/connection-name references structurally. Redact sensitive values; connection names do not identify a verified database deployment |
| `.sql` | Locate candidate procedure definitions and collect direct excerpts. Declare supported dialect/schema/name rules; no SQL execution or invented definition |
| Binary `.rpt` | Inventory/hash and referenced-path evidence first. Optional bounded string extraction is lexical-only, records extractor/version and byte offsets, and cannot establish report semantics or absence |

XML extraction must be bounded and avoid external entity/DTD resolution or network/file fetches. Retain original source locations and namespace/schema context; do not reserialize XML and cite its new line numbers.

For a procedure reference with no located definition, distinguish:
- `not_found_in_searched_scope` after a complete supported search of that scope;
- `unresolved_due_to_incomplete_coverage` when repositories/files were skipped, capped or failed;
- `external_definition_confirmed` only when separate evidence establishes an external definition.

Do not infer “not in any approved repository” from a capped search, and do not infer that a source definition matches the deployed database version.

## Declaration candidates across files

Add a bounded, paged per-repository declaration index keyed to source snapshot and parser configuration. Include namespaces, containing types/modules, partial modifiers, declaration kind/name, path and spans, including `*.Designer.vb`.

Lookups return candidate declarations and an ambiguity count (exact only when the lookup scope is complete), plus scope and coverage metadata. Namespace/type-name matches across partial declarations are grouping candidates until project/semantic context establishes identity. Unqualified module calls produce candidate targets rather than resolved links. Do not merge duplicate names across repositories or projects.

This index is in the report-tracing MVP; a fully resolved call graph remains deferred. Build incrementally/on demand under explicit limits and report incomplete indexing instead of silently scanning all 15 repositories.

## Component boundary

The parser is a versioned .NET executable invoked by the Node server using an argument array with `shell: false`. Expose repository-relative logical paths in evidence; strip staging paths and user-home paths from results and errors. A PowerShell launcher remains optional for personal/manual use; the server must not depend on personal shell profiles or a specific user's home directory.

| Parser owns | Harness owns |
|---|---|
| Parsing supplied VB source | Approved aliases, paths, and source selection |
| Syntax extraction and source spans | Commit/blob identity and decoding policy |
| Parser options and diagnostic reporting | Timeouts, cancellation, input/output limits |
| Stable structured observations | Redaction, evidence IDs, persistence, validation |

Do not introduce a second MCP server for the MVP. Keep the parser independent of Git, repository configuration, artifact manifests, and model providers.

## Proposed interface

Proposed MCP tool name: `analyze_vb_source`. The name is not a currently available tool.

Inputs: approved `repositoryAlias`, normalized `relativePath`, an operation enum (`outline`, `inspect`, `invocations`, `report-references`), optional declaration selection, and bounded pagination/limit fields. Add focused artifact-inspection and declaration-candidate lookup operations with their own schemas rather than overloading the VB parser with arbitrary file formats. The server owns the pinned revision and effective parser configuration; callers do not supply arbitrary executable paths, root paths, or compiler arguments.

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
- Add the report-relationship extractors listed under "Report relationships required in the MVP": object creation, member assignments, nearest `With` receivers, `Handles` clauses, and syntactic positional/named argument mapping with literal values. The 0.1.0 `calls` command excludes object creation and assignments, so it cannot produce these observations today.
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

Prerequisite regressions must cover a late match beyond 16 KiB, 601+ matches across multiple files, file-oriented pagination, unknown totals on early termination, a Windows path set exceeding the single-command budget, non-ASCII Windows-1252 literals, BOM Unicode input, and restart/reload reference validation. Do not mark the Windows case validated from Linux tests alone.

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

For the report-tracing MVP, create a multi-repository fixture containing `New rptX()`, literal `.rpt` and `.rdlc` references, an `.rdlc`, a typed `.xsd`, `.vbproj` item metadata, a `With cmd` block with `CommandText`/`CommandType`, `AddWithValue`, a `Handles` clause, a Designer partial class, and both present and absent procedure-definition candidates. Include duplicate names, misleading comments, nested `With` blocks, a dynamic report path, and an explicitly unsupported binary report. Verify the expected file/relationship set and ambiguity/coverage states. Do not invent a complete path when a target or procedure definition remains unresolved.

Measure against the corrected lexical/excerpt baseline (retain pre-fix measurements only as historical context): supported findings, false relationship claims, unresolved links, tool calls, returned bytes, and elapsed time. Do not use explanation fluency as the acceptance metric. Test larger repository counts and practical corpus sizes before claiming 15-repository scalability.

## Deferred work

Full solution loading, semantic binding, overload resolution, complete call graphs, dynamic SQL evaluation, runtime tracing, automatic modernization, model inference, vector databases, and additional agents are outside this MVP. Add them only for demonstrated unanswered questions.

## Rollout

1. Reconcile this proposal against the downstream fork and agree on contracts.
2. Land and validate prerequisite harness fixes. Parser-only experiments may proceed independently; integration acceptance is gated on these fixes.
3. Build/test the report-relevant parser extractors, XML artifact adapter and candidate index; add optional MCP tools while preserving existing contracts.
4. Run the synthetic report investigation and compare against the corrected search/excerpt baseline.
5. Pilot selected real reports locally; retain explicit coverage and unresolved links.
6. Expand scope after evidence quality and measured performance pass review.

## References

- ripgrep path-list limitation: https://github.com/BurntSushi/ripgrep/issues/3459
- ripgrep encoding: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#file-encoding
- Public baseline: https://github.com/jeffcaradona/modernization-evidence-harness/tree/baa4158bbc09b0d7143d1b006bc6b0607e3baa88
- Architecture: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/architecture.md
- Evidence contract: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/evidence-and-artifacts.md
- Adding tools: https://github.com/jeffcaradona/modernization-evidence-harness/blob/baa4158bbc09b0d7143d1b006bc6b0607e3baa88/docs/adding-a-tool.md
