#!/usr/bin/env bash
set -euo pipefail

patch="${1:?usage: patch_index.sh <file.patch> [path line [new|old]]}"
want_path="${2:-}"
want_line="${3:-}"
side="${4:-new}"

index() {
  awk '
    BEGIN { OFS = "\t"; print "patch_line", "commit", "file", "old_line", "new_line", "op" }
    function strip(p) { sub(/^[ab]\//, "", p); sub(/\t.*$/, "", p); return p }
    ro > 0 || rn > 0 {
      op = ($0 == "" ? " " : substr($0, 1, 1))
      if (op == "\\") next
      if (op == " ") { print NR, commit, file, o, n, "ctx"; o++; n++; ro--; rn--; next }
      if (op == "-") { print NR, commit, file, o, "", "del"; o++; ro--; next }
      if (op == "+") { print NR, commit, file, "", n, "add"; n++; rn--; next }
      ro = 0; rn = 0
    }
    /^From [0-9a-f]{40} / { commit = substr($2, 1, 12); next }
    /^--- / { old = strip(substr($0, 5)); next }
    /^\+\+\+ / {
      new = strip(substr($0, 5))
      file = (new == "/dev/null" ? old : new)
      next
    }
    /^@@ / {
      match($0, /-[0-9]+(,[0-9]+)?/); h = substr($0, RSTART + 1, RLENGTH - 1)
      split(h, a, ","); o = a[1] + 0; ro = (2 in a ? a[2] + 0 : 1)
      match($0, /\+[0-9]+(,[0-9]+)?/); h = substr($0, RSTART + 1, RLENGTH - 1)
      split(h, b, ","); n = b[1] + 0; rn = (2 in b ? b[2] + 0 : 1)
      delete a; delete b
      next
    }
  ' "$patch"
}

if [ -z "$want_path" ]; then
  index
  exit 0
fi

col=5
[ "$side" = "old" ] && col=4
index | awk -F'\t' -v p="$want_path" -v l="$want_line" -v c="$col" -v f="$patch" '
  NR > 1 && ($3 == p || $3 ~ ("(^|/)" p "$")) && (l == "" || $c == l) {
    printf "%s:%s  ->  %s:%s  (%s%s)\n", f, $1, $3, $c, $6, ($2 != "" ? ", commit " $2 : "")
    found = 1
  }
  END { if (!found) { print "Not found in " f ": " p (l != "" ? ":" l : ""); exit 1 } }'
