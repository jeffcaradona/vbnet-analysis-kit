# Report tracing across repositories

Use this recipe for questions such as "which files generate report X". The goal is a
cited set of participating files with explicit coverage and unresolved links, not a
fluent narrative.

## 1. Fix scope and snapshot identity

List every repository in scope before searching. For each one, record its identity
with read-only commands:

```powershell
git -C $repo rev-parse HEAD
git -C $repo --no-optional-locks status --porcelain
```

Record the commit and whether the working tree has local changes. Standalone
observations are uncataloged either way; the commit makes them reproducible, and a
dirty tree must be stated next to every finding from that repository.

In a harness investigation, use the snapshot the harness reports instead.

## 2. Search in this order

Use `rg --fixed-strings` unless a pattern is genuinely needed. If `fd` is unavailable,
list files with `rg --files -g "<glob>"`. Run each step in every in-scope repository and
log it in the coverage ledger (section 4).

| Step | What to find | Starting searches |
|---|---|---|
| 1. Identifier | Report ID, title, menu caption, file stem | the identifier and its variants (spacing, prefixes such as `rpt`) |
| 2. Report definitions | `.rpt`, `.rdlc`, `.rdl`, typed `.xsd`, and `.vbproj` items naming them | `rg --files -g "*.rpt" -g "*.rdlc" -g "*.rdl" -g "*.xsd"`; the file stem in `*.vbproj` |
| 3. Report construction | Typed report classes, document loads, report paths | `New rpt`, `ReportDocument`, `.Load(`, `ReportPath`, `ReportSource`, `LocalReport` |
| 4. Entry points | Handlers that start the report | `Handles` on the enclosing method; the menu/button name from step 1 |
| 5. Data access | Stored procedures and parameters | `CommandText`, `CommandType.StoredProcedure`, `SqlCommand("`, `AddWithValue("@`, `Parameters.Add(` |
| 6. Procedure definitions | Where each procedure name is defined, if anywhere | the procedure name in `*.sql`; `CREATE PROCEDURE` / `ALTER PROCEDURE` |

Then use the Roslyn launcher only to bound each hit:

- `outline` the file and find the declaration that contains the hit line;
- `inspect` that declaration to read the whole method instead of guessing its extent;
- `calls` for invocation candidates inside it.

`calls` excludes object creation and assignments. Steps 3 and 5 are text-search
evidence until the parser gains those extractors; label them as lexical.

### Known traps

- **`With` blocks:** `.CommandText = "usp_X"` inside `With cmd` has no receiver on the
  line. Inspect the enclosing method to find the `With` expression, and report it as
  receiver syntax, not a proven object.
- **Designer partial classes:** a form's controls and `Handles` targets may live in
  `*.Designer.vb`. Search both files of a partial class.
- **Unqualified module calls:** `Helper()` may match same-named methods in several
  modules or repositories. Report every candidate with its count; never pick one silently.
- **Dynamic names:** a concatenated report path or procedure name stays unresolved.
  Quote the expression; do not guess the value.
- **Binary `.rpt`:** inventory and hash it. `rg -a` on it is lexical only and may miss
  UTF-16 strings; a miss does not prove absence.

## 3. Harness mode

Run the same steps through the harness tools instead of the terminal. Until its
prerequisite fixes land (see the integration proposal):

- If `search_repository` returns exactly the configured `maxSearchMatches` items
  (default 20), treat the result as possibly truncated. Narrow the query; do not
  conclude that unlisted files lack matches.
- `E_LINE_RANGE_INVALID` for a line that search reported is a harness read limit on
  large files, not evidence that the line is missing. Record it as a coverage gap.

## 4. Coverage ledger

Keep one row per repository and step:

| Repository | Commit | Dirty | Step | Query / glob | Result | Capped / failed |
|---|---|---|---|---|---|---|

A repository or step that was not run is listed as not searched. Never fold it into
"no matches".

## 5. Answer format

Answer with these sections, in this order.

**Participating files**

| Repo@commit | Path | Lines | Role | Evidence | Status |
|---|---|---|---|---|---|

- Role is one of: entry point, report definition, report construction, data access,
  procedure definition, helper.
- Evidence is one of: lexical (text search), syntax (Roslyn), direct read, or a harness
  evidence ID returned in this session.
- Status is resolved or candidate, with the ambiguity count for candidates.

**Stored procedures:** each name with its definition location, or one of:
`not_found_in_searched_scope` (all in-scope repositories fully searched),
`unresolved_due_to_incomplete_coverage`, or `external_definition_confirmed` (only with
separate evidence).

**Unresolved:** dynamic paths and names, ambiguous candidates, unsupported files.

**Coverage:** the ledger from section 4, or a summary of it plus every gap.

Use repository-relative paths. Do not paste absolute local paths into the answer.
