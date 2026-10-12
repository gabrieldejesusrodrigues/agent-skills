#!/usr/bin/env bash
set -euo pipefail

if [ -t 0 ]; then
  echo "usage: git diff -U0 -M <merge-base> HEAD -- <paths> | mechanical_check.sh" >&2
  echo "       mechanical_check.sh [path...] < changes.patch" >&2
  exit 2
fi

limit="${MECHANICAL_SHOW:-40}"
want="$(printf '%s\n' "$@")"

awk -v limit="$limit" -v want="$want" '
  BEGIN { nw = split(want, w, "\n") }
  function strip(p) { sub(/^[ab]\//, "", p); sub(/\t.*$/, "", p); return p }
  function norm(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
  function wanted(f,   i) {
    if (nw == 0 || (nw == 1 && w[1] == "")) return 1
    for (i = 1; i <= nw; i++) if (w[i] != "" && (f == w[i] || index(f, w[i] "/") == 1)) return 1
    return 0
  }
  function record(op, f, line, text,   k) {
    k = norm(text)
    if (k == "" || !wanted(f)) return
    ne++; eop[ne] = op; efile[ne] = f; eline[ne] = line; etext[ne] = text; ekey[ne] = k
    count[op, k]++
  }
  ro > 0 || rn > 0 {
    op = ($0 == "" ? " " : substr($0, 1, 1))
    if (op == "\\") next
    if (op == " ") { o++; n++; ro--; rn--; next }
    if (op == "-") { record("-", old, o, substr($0, 2)); o++; ro--; next }
    if (op == "+") { record("+", new, n, substr($0, 2)); n++; rn--; next }
    ro = 0; rn = 0
  }
  /^diff --git / { old = ""; new = ""; sim = ""; rfrom = ""; next }
  /^similarity index / { sim = $3; next }
  /^rename from / { rfrom = substr($0, 13); next }
  /^rename to / {
    rto = substr($0, 11)
    if (wanted(rfrom) || wanted(rto)) renames[++nr] = rfrom " => " rto " (similarity " sim ")"
    next
  }
  /^--- / { old = strip(substr($0, 5)); next }
  /^\+\+\+ / {
    new = strip(substr($0, 5))
    if (new == "/dev/null") new = old
    if (old == "/dev/null") old = new
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
  END {
    print "== Renames"
    if (nr == 0) print "  none"
    for (i = 1; i <= nr; i++) print "  " renames[i]

    for (i = 1; i <= ne; i++) {
      k = ekey[i]
      if (eop[i] == "-") removed++; else added++
      cm = count["-", k] + 0; cp = count["+", k] + 0
      if (used[eop[i], k] + 0 < (cm < cp ? cm : cp)) { used[eop[i], k]++; if (eop[i] == "+") moved++ }
      else { left[i] = 1; nleft++ }
    }

    print ""
    printf "== Changed lines: %d removed, %d added (blank lines and indentation ignored)\n", removed, added
    printf "Moved or reordered: %d line pair(s)\n", moved
    printf "Not explained by moves or renames: %d line(s)\n", nleft
    shown = 0
    for (i = 1; i <= ne && shown < limit; i++) {
      if (!(i in left)) continue
      t = etext[i]; if (length(t) > 120) t = substr(t, 1, 117) "..."
      printf "  %s %s:%d%s  %s\n", eop[i], efile[i], eline[i], (eop[i] == "-" ? " (base)" : ""), t
      shown++
    }
    if (nleft > shown) printf "  ... %d more (MECHANICAL_SHOW raises the limit)\n", nleft - shown

    print ""
    if (ne == 0 && nr == 0) print "RESULT: no changed lines in the selected paths"
    else if (nleft == 0) print "RESULT: mechanical (renames, moves, reordering and indentation only)"
    else printf "RESULT: %d line(s) beyond moves and renames: read them before calling this supporting\n", nleft
    print "Lines are matched by content, so common lines (a closing brace, return null) can pair up by chance: evidence, not proof."
  }'
