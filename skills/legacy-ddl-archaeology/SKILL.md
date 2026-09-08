---
name: legacy-ddl-archaeology
description: Use when facing a large legacy database dump (DDL and/or stored procedures) that must be understood before a migration, a rewrite, or a domain redesign — typically an Oracle/SQL Server/DB2 schema export of hundreds of MB to several GB where the business rules live in the code, not in the schema. Covers profiling the dump, splitting it by object, separating generated scaffolding from hand-written logic, recovering a data model that has no foreign keys, and extracting business rules per feature. Skip for small schemas you can read in one sitting, or for greenfield design.
---

# Legacy DDL archaeology

**Principle:** a multi-GB dump is not "a lot of DDL" — it is a few hundred MB of real
structure buried under generated scaffolding, operational noise, and repetition. Measure
what is in it *before* reading any of it, and never split it by byte count. The unit is the
object, and later the stored-procedure unit; the chunk size follows from that, not the
other way around.

**Use when** you must answer "what does this system do and why" from a dump alone.
**Skip** when the schema fits in one reading session, or when nothing depends on the legacy.

## Phase 1 — Profile before reading

Never open the file at a random offset and start forming opinions. Count first.

1. **Line and byte totals**, then the header — most export tools (Toad, SQL Developer,
   `expdp` with `sqlfile`) write a banner naming the tool, DB version and schema.
2. **Object census by type.** Exporters delimit each object with a comment header. Detect
   that pattern, then aggregate bytes and counts per object type.
3. **Read the resulting table before anything else.** It routinely overturns the framing:
   tables and indexes are often <5% of the file, while stored-procedure bodies are >50%.

Do not trust an "Object Counts" banner in the header — it may describe one schema while the
file concatenates many. Count them yourself.

**Watch for concatenated exports.** A single file often holds one export per schema, each
with its own banner. Find those boundaries early; they define the coarse structure.

## Phase 2 — Split by object, never by size

Fixed-size chunks cut a `CREATE TABLE` in half and produce fragments with no identity. Split
on the exporter's own object headers into `<schema>/<type>/<NAME>.sql`, and aggregate the
small-and-numerous types (indexes, synonyms, sequences, grants) into one file per schema so
you don't create 300k files.

**Always verify the split is lossless**: total lines in equals total lines out. See
`references/splitting.md`.

Then build an inventory: `schema, type, name, start_line, line_count, bytes`. One pass, and
it becomes the backbone for everything after.

**For stored-procedure bodies, index units instead of materializing them.** Record
`file, unit_name, start_line, end_line` and extract on demand with `sed -n 'start,endp'`.
Typical unit size is well under 200 lines — a natural chunk — and you avoid writing hundreds
of thousands of files.

## Phase 3 — Separate generated code from hand-written code

This is the highest-leverage step and the least obvious. Enterprise legacy systems are
mostly **scaffolding generated per entity**, and reading it teaches you nothing.

**The metric that works: unique-line ratio.** Normalize each line (collapse whitespace,
replace string literals and numbers with placeholders), then measure distinct lines over
total lines per layer.

```
3–6%   → generated. Read ONE instance, document the pattern, ignore the rest.
15–20% → mostly generated with some hand edits.
30–50% → hand-written. This is where the rules live.
```

Corroborating signal: **layers with zero `RAISE`/`THROW` statements across millions of lines
are generated.** Nobody wrote an error message there.

Find the layers by naming convention — suffixes or prefixes on procedure/package names
usually encode the architectural layer. Count them; near-identical counts across three
suffixes means a generated triple per entity.

Subtracting these layers commonly removes 60–80% of the corpus without losing a single rule.

## Phase 4 — Find where the rules actually are

**Rank by hand-written markers, not by logic density.** Counting `IF`/`CASE` favors
generated validation code, which is full of repetitive branches. Rank by
**`RAISE_APPLICATION_ERROR` (or equivalent) per KLOC** — someone had to write that message.

Sources in order of cost-effectiveness:

1. **Column and table comments.** `COMMENT ON COLUMN` is documentation written by humans,
   in the local language, often containing the whole rule (`X = Y + Z`), and it is the
   cheapest source in the file. Index it and consult it *before* reading code.
2. **Error messages** raised in code — each is an invariant already phrased in natural
   language. If they are passed as variables rather than literals, the catalog lives in a
   *table* (common in multilingual products), and you need a data export, not more DDL.
3. **High-`RAISE` hand-written layers**, unit by unit.

## Phase 5 — Recover the model when there are no foreign keys

Mature legacy schemas frequently declare almost no referential integrity — integrity is
enforced in application code. Check before assuming: count PKs and FKs against table count.
Beware constraints *named* like FKs that are actually CHECK constraints.

When FKs are absent, recover relationships from:

- **Column naming conventions.** `<ABBREV>_<ENTITY>_ID` is near-universal. Aggregate by
  entity across all tables: **frequency reveals centrality**, and it crosses schema
  boundaries — which is exactly what you want, because schema boundaries encode the *old*
  design.
- **Dependency blocks emitted by the exporter.** Many tools write a `Dependencies:` comment
  per object, straight from the data dictionary. This is a real call/usage graph, free.
- **Synonym/alias maps**, to resolve cross-schema references to physical tables.
- **Row counts**, when the exporter records them: they separate live entities from dead
  tables and size the migration.

**Do not organize your study by schema.** Schemas encode the vendor's or the original team's
domain model. If you study in that order you will rebuild their model — usually the thing a
redesign is trying to escape. Organize by entity centrality instead.

## Traps that cost hours

**Encoding.** Dumps are frequently Latin-1/ISO-8859, not UTF-8 — and the non-ASCII bytes
cluster in exactly the locally-written parts (the customizations you most want). `grep`
treats such files as binary and **skips them silently, with no error**. An empty result may
mean "no match" or "never read". Use `grep -a` everywhere and pipe through
`iconv -f LATIN1 -t UTF-8` to display. Verify with `file` when a search returns suspiciously
few hits.

**Language.** Vendor products carry the vendor's language. Searching in your language finds
nothing, and dictionary translations of domain terms often don't match the product's actual
vocabulary either. **Derive the vocabulary from the data**: tokenize object names and rank by
frequency. Then note which terms appear in *your* language — those mark local customizations,
which are the least documented and highest-risk parts of the system.

**Temporal keys.** Many enterprise schemas are bi-temporal: identity is
`(id, valid_from, version)`, not a simple id, and every join needs validity and
not-cancelled predicates. Omitting one silently returns historical rows. Measure how much of
the schema is bi-temporal before deciding whether a rewrite inherits it.

**Operational noise.** Scheduler jobs, one-shot maintenance entries and mass grants can
dominate a dump by volume while carrying no domain meaning. Check whether recurring jobs even
live here — if nearly all jobs lack a repeat interval, the real scheduler is an external
orchestrator and the batch process inventory is not in this file.

**`awk` portability.** `mawk` is dramatically faster than `gawk` on multi-GB files but
rejects `{n,m}` regex intervals and some POSIX classes. Write portable patterns.

## What a dump cannot tell you

Say so explicitly instead of inferring: application entry points (grants are usually
mass-assigned per role and don't identify a public API), external batch orchestration,
message/parameter catalogs held as *data*, and anything requiring runtime behavior. List
these as questions to answer from other sources — asking for three specific table exports
often beats weeks of code reading.

## Deliverable shape

Produce a navigable tree plus indexes (catalog, unit index, comment index, dependency graph,
row counts), and per-feature notes that separate **essential** business rules from
**accidental** ones inherited from the product, its original jurisdiction, or the technology.
Without that column, a rewrite ports the accidental parts by osmosis.

See `references/recipes.md` for concrete commands.
