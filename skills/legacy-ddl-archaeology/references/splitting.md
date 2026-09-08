# Splitting a dump losslessly

## Identify the object header pattern

Most exporters delimit objects with a comment block. Toad and SQL Developer emit:

```
--
-- OBJECT_NAME  (Type)
--
```

Confirm the exact shape in your file before writing the splitter, and validate the type
against a **whitelist** of real object types. Without a whitelist, comments inside procedure
bodies get parsed as headers — in one real dump this misattributed >1 GB to the wrong type.

## The one-line buffer

The blank `--` line above a header belongs to the *next* object. Buffer one line so you can
switch output files before writing it:

Fragment — you supply `header_target(line)`, returning the output path for a valid object
header or `""` otherwise:

```awk
{
  cur = $0; sub(/\r$/, "", cur)          # dumps are often CRLF
  if (have) {
    if (buf == "--") {
      nf = header_target(cur)             # "" if cur is not a valid header
      if (nf != "" && nf != out) { close(out); out = nf }
    }
    print buf >> out
  }
  buf = cur; have = 1
}
END { if (have) print buf >> out; close(out) }
```

`close()` on every switch matters: without it you exhaust file descriptors.

## Pre-create directories

`awk` cannot create directories, and calling `system("mkdir -p")` per object is slow. Build
the inventory first, derive the unique directory list from it, and create them in one
`xargs mkdir -p`.

## Verify

Non-negotiable, and it catches buffer bugs immediately:

```bash
wc -l < dump.sql
find out -name '*.sql' -print0 | xargs -0 cat | wc -l   # must match exactly
```

## Indexing stored-procedure units

Do not write one file per unit. Emit `file, kind, name, start_line, end_line, lines`.

Detect top-level units by the **minimum indentation** at which `PROCEDURE`/`FUNCTION`
appears in each file, computed per file in a first pass and applied in a second. A fixed
indentation guess promotes nested functions to top-level units. Skip comment lines before
matching, and expect overloads — the same name legitimately appears more than once.

Extract on demand:

```bash
sed -n '2498,2564p' path/to/PACKAGE_BODY.sql
```
