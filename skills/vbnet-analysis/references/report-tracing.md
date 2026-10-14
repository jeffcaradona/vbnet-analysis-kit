# Report tracing across repositories

Use this recipe for questions such as "which files generate report X". The goal is a
cited set of participating files with explicit coverage and unresolved links, not a
fluent narrative.

## 1. Fix scope and source identity

List every repository in scope before searching. For each one, record context with
read-only commands:

```powershell
git -C $repo rev-parse HEAD
git -C $repo --no-optional-locks status --porcelain
```

The commit and dirty state are context only. They do not make standalone observations
reproducible, because the parser and search read working-tree files.

For every file a standalone finding cites, record the identity of the content actually
analyzed:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash
git -C $repo rev-parse "HEAD:$relativePath"   # committed blob, if tracked
git -C $repo hash-object --no-filters -- $relativePath # raw working-tree bytes
```

- If the two Git hashes match, the analyzed content matches the committed blob; cite
  `repo@commit:path` with the blob hash.
- Otherwise, or if the file is untracked, label the finding **working-tree content** and
  cite the SHA-256 instead. Do not attribute it to the commit.
- `--no-filters` prevents clean filters and end-of-line normalization from changing
  the bytes being hashed. `hash-object` without `-w` writes nothing.
- Retain the raw SHA-256 even when the Git hashes match.

**Re-encoded copies:** if a file must be converted (for example, Windows-1252 to UTF-8)
before parsing, record the original encoding, the conversion performed, and the
SHA-256 of both the original and the copy. Perform an encoding-only conversion:
strictly decode each file using its recorded encoding and verify that the decoded
text is identical, including every line break. Do not normalize newlines, replace
undecodable characters, or otherwise edit the text. Equal line counts alone do not
establish preserved line mapping. If decoded-text equality cannot be verified,
do not cite the copy's line numbers against the original; record the limitation.
Always cite the original path, never the copy's.

In a harness investigation, use the snapshot and evidence identity the harness reports
instead.

## 2. Search order

Use `rg --fixed-strings` unless a pattern is genuinely needed. If `fd` is unavailable,
list files with `rg --files -g "<glob>"`. Run each step in every in-scope repository and
log it in the coverage ledger (section 4).

| Step | What to find | Starting searches |
|---|---|---|
| 1. Identifier | Report ID, title, menu caption, file stem | the identifier and its variants (spacing, prefixes such as `rpt`) |
| 2. Report definitions | `.rpt`, `.rdlc`, `.rdl`, typed `.xsd`, and `.vbproj` items naming them | `rg --files -g "*.rpt" -g "*.rdlc" -g "*.rdl" -g "*.xsd"`; the file stem in `*.vbproj` |
| 3. Indirect references | Report paths, names or keys held in configuration or resources | the identifier and file stem in `*.config` and `*.resx`; `appSettings` keys and resource names that hold them |
| 4. Report construction | Typed report classes, document loads, report paths | `New rpt`, `ReportDocument`, `.Load(`, `ReportPath`, `ReportSource`, `LocalReport`; config keys and resource names found in step 3 |
| 5. Entry points | Handlers that start the report | `Handles` on the enclosing method; the menu/button name from step 1 |
| 6. Data access | Stored procedures and parameters | `CommandText`, `CommandType.StoredProcedure`, `SqlCommand("`, `AddWithValue("@`, `Parameters.Add(` |
| 7. Procedure definitions | Where each procedure name is defined, if anywhere | the procedure name in `*.sql`; `CREATE PROCEDURE` / `ALTER PROCEDURE` |

**Follow references iteratively.** Each newly discovered name, such as a report file
stem, class, config key, resource name, helper method or procedure, becomes a new query
across all in-scope repositories. Repeat until a pass yields no new names. Log each pass
in the ledger.

**Bound each hit with Roslyn:**

- `outline` the file and find the declaration that contains the hit line;
- `inspect` that declaration and check `textTruncated`. If it is true, read the rest
  through additional bounded excerpts (harness range reads, or bounded source reads in
  standalone mode). If that is not possible, record the inspection as incomplete;
- `calls` for invocation candidates inside it.

`calls` excludes object creation and assignments. Steps 4 and 6 are text-search
evidence until the parser gains those extractors; label them as lexical.

### Known traps

- **`With` blocks:** `.CommandText = "usp_X"` inside `With cmd` has no receiver on the
  line. Inspect the enclosing method to find the `With` expression, and report it as
  receiver syntax, not a proven object.
- **Partial classes:** a form's controls and `Handles` targets may live in
  `*.Designer.vb` or other files. Find all matching partial declarations of the type
  and search each one.
- **Unqualified module calls:** `Helper()` may match same-named methods in several
  modules or repositories. Report every candidate with its count; never pick one silently.
- **Dynamic names:** a concatenated report path or procedure name stays unresolved.
  Quote the expression; do not guess the value.
- **Binary `.rpt`:** inventory and hash it. `rg -a` on it is lexical only and may miss
  UTF-16 strings; a miss does not prove absence.

## 3. Harness mode

Run the same steps through the harness tools instead of the terminal. Two coverage
defects were reproduced against upstream harness `baa4158`. Check whether the
downstream harness in use still behaves this way (its version, tool output, or
documentation) before relying on these notes:

- **Search cap:** at `baa4158`, `search_repository` stops at `maxSearchMatches`
  (default 20) without a completeness flag. If a search returns exactly the cap and the
  tool reports no completeness information, treat the result as possibly truncated.
  Narrow the query; do not conclude that unlisted files lack matches.
- **Late-line reads:** at `baa4158`, range reads fail beyond a 16 KiB prefix with
  `E_LINE_RANGE_INVALID`. If a range read fails for a line that search reported, record
  a coverage gap with the error code. It is consistent with that defect, but do not
  diagnose every such failure as that defect.

## 4. Coverage ledger

Keep one row per repository, step and pass:

| Repository | Commit (context) | Dirty | Pass | Step | Query / glob | Result | Capped / failed |
|---|---|---|---|---|---|---|---|

A repository or step that was not run is listed as not searched. Never fold it into
"no matches".

## 5. Answer format

Answer with these sections, in this order.

**Participating files**

| Repository | Path | Content identity | Lines | Role | Evidence kind | Harness evidence ID | Status |
|---|---|---|---|---|---|---|---|

- **Content identity:** the commit and blob hash, or the SHA-256 labelled working-tree
  content (section 1).
- **Role:** entry point, report definition, indirect reference, report construction,
  data access, procedure definition, or helper.
- **Evidence kind:** lexical (text search), syntax (Roslyn), or direct read.
- **Harness evidence ID:** an ID returned by the harness in this session, or
  `uncataloged`. An ID establishes provenance, not semantic resolution.
- **Status:**
  - `observed`: the cited text or syntax exists at that location;
  - `candidate`: a relationship is suggested but not established, with the ambiguity
    count;
  - `confirmed`: only when separate supporting evidence for the relationship is cited.

  Finding a file or reading a literal is `observed`; it does not confirm that the
  relationship executes.

**Stored procedures:** each name with its definition location, or one of:
`not_found_in_searched_scope` (all in-scope repositories fully searched),
`unresolved_due_to_incomplete_coverage`, or `external_definition_confirmed` (only with
separate evidence).

**Unresolved:** dynamic paths and names, ambiguous candidates, incomplete inspections,
unsupported files.

**Coverage:** the ledger from section 4, or a summary of it plus every gap.

Use repository-relative paths. Do not paste absolute local paths into the answer.
