# Recipes

All examples assume `mawk` for speed. Add `-a` to **every** `grep` — see the encoding trap.

## Object census by type

```awk
# profile.awk — bytes and counts per object type
BEGIN {
  split("Table|Index|View|Sequence|Synonym|Package|Package Body|Procedure|Function|" \
        "Trigger|Type|Type Body|Scheduler Job|Directory|Role|User|Tablespace", W, "|")
  for (i in W) OK[W[i]] = 1
}
{
  line = $0; sub(/\r$/, "", line)
  if (prev == "--" && substr(line,1,3) == "-- ") {
    t = line; sub(/[ \t]+$/, "", t)
    if (match(t, /\([A-Za-z][A-Za-z ]*\)$/) && RSTART > 3) {
      ty = substr(t, RSTART+1, RLENGTH-2)
      if (ty in OK) { curType = ty; CNT[ty]++ }
    }
  }
  B[curType] += length($0) + 1
  prev = line
}
END { for (t in B) printf "%-20s %8d objects %12.1f MB\n", t, CNT[t], B[t]/1048576 }
```

## Generated vs hand-written (unique-line ratio)

The decisive metric. Sample ~25 files per layer; normalize before comparing.

```bash
for suf in _INF _SVC _DAO _PKG; do        # replace with your layer suffixes
  ls */procs/*${suf}.sql 2>/dev/null | shuf -n 25 | xargs cat \
  | sed -E "s/'[^']*'/S/g; s/[0-9]+/N/g; s/[[:space:]]+/ /g" | grep -vE '^ *$' > /tmp/n
  tot=$(wc -l < /tmp/n); uniq=$(sort -u /tmp/n | wc -l)
  printf "%-6s %6.1f%% unique\n" "$suf" "$(echo "100*$uniq/$tot" | bc -l)"
done
```

## Rank files by hand-written markers

```bash
# RAISE per KLOC — not IF/CASE density
awk -F'\t' 'NR>1 && $2>0 {printf "%-50s %6.2f raise/kloc\n", $1, 1000*$5/$2}' density.tsv \
  | sort -k2 -rn | head -20
```

## Entity centrality from column names

```awk
# every  <ABBREV>_<ENTITY>_ID  column is a relationship the schema never declared
/^  [A-Z]/ {
  col = $1
  if (col ~ /_ID$/) {
    ent = col; sub(/^[A-Z0-9]+_/, "", ent); sub(/_ID$/, "", ent)
    if (length(ent) > 2) print FILENAME "\t" ent
  }
}
```

Aggregate by entity for centrality, and by `(schema, entity)` to see which entities cross
schema boundaries — those are your shared kernel; the narrow ones are candidate bounded
contexts.

## Dependency graph from exporter metadata

If the dump carries `Dependencies:` blocks, harvest them — it is the data dictionary's own
graph:

```awk
/^--  Dependencies:/ { indep = 1; next }
indep {
  line = $0; sub(/\r$/, "", line); sub(/[ \t]+$/, "", line)
  if (line !~ /^--   / || !match(line, /\([A-Za-z][A-Za-z ]*\)$/)) { indep = 0; next }
  print FILENAME "\t" substr(line, 6, RSTART-6) "\t" substr(line, RSTART+1, RLENGTH-2)
}
```

## Column comments — the cheapest documentation

Comments may wrap across lines, so accumulate until the terminating `;`:

```awk
/^COMMENT ON (COLUMN|TABLE)/ {
  line = $0; sub(/\r$/, "", line)
  while (line !~ /;[ \t]*$/ && (getline nxt) > 0) { sub(/\r$/, "", nxt); line = line " " nxt }
  if (match(line, /IS[ \t]+'/)) {
    txt = substr(line, RSTART+RLENGTH); sub(/'[ \t]*;[ \t]*$/, "", txt)
    gsub(/\t/, " ", txt); print line "\t" txt
  }
}
```

## Derive the domain vocabulary

```bash
ls */tables/*.sql */procs/*.sql | sed 's#.*/##;s#\.sql$##' \
  | tr '_' '\n' | grep -E '^[A-Z]{4,}$' | sort | uniq -c | sort -rn | head -40
```

Rank, then translate the top terms with a domain expert. Terms appearing in the local
language (rather than the vendor's) mark customizations — highest risk, least documented.

## Checking for real referential integrity

```bash
for k in "PRIMARY KEY" "FOREIGN KEY" "UNIQUE" "CHECK"; do
  printf "%-12s %d\n" "$k" \
    "$(grep -rahc "^[[:space:]]*$k" --include='*.sql' */tables | awk '{s+=$1} END{print s+0}')"
done
```

Constraints are usually multi-line (`ALTER TABLE x ADD (\n  PRIMARY KEY ...)`), so anchor on
the keyword's own line, not on `ADD`. If FKs are near zero, the model lives in the code.
