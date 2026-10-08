#!/usr/bin/env bash
set -euo pipefail

base="${1:-origin/main}"
head="${2:-HEAD}"
recent_days="${PR_REVIEW_RECENT_DAYS:-180}"
notes_root="${PR_REVIEW_HOME:-$HOME/.pr-reviews}"
emails="${PR_REVIEW_EMAILS:-$(git config user.email || true)}"

mb="$(git merge-base "$base" "$head")"
remote="$(git remote get-url origin 2>/dev/null || basename "$(git rev-parse --show-toplevel)")"
repo_key="$(sed -E 's#\.git$##; s#^.*[:/]([^/]+)/([^/]+)$#\1__\2#' <<<"$remote")"
notes_dir="$notes_root/$repo_key"

author_args=()
IFS=',' read -ra email_list <<<"$emails"
for e in "${email_list[@]}"; do
  e="$(xargs <<<"$e")"
  [ -n "$e" ] && author_args+=("--author=$e")
done

echo "== Reviewer: ${emails:-unknown} (PR_REVIEW_EMAILS=a@x,b@y adds identities)"
echo "== Notes dir: $notes_dir"
echo "== History up to the merge base $(git rev-parse --short "$mb"); recent = last $recent_days days"
echo

if [ "${#author_args[@]}" -eq 0 ]; then
  echo "No reviewer identity found (git config user.email is empty). Set PR_REVIEW_EMAILS."
  exit 0
fi

changed="$(git diff --name-only --no-renames "$mb" "$head")"
if [ -z "$changed" ]; then
  echo "No changes between $base and $head."
  exit 0
fi

cutoff=$(( $(date +%s) - recent_days * 86400 ))
areas="$(awk -F/ '{ print (NF > 2 ? $1 "/" $2 : (NF == 2 ? $1 : "(root)")) }' <<<"$changed" | sort -u)"

printf "%-32s %6s %7s  %-20s %-9s %s\n" "area" "yours" "recent" "your last" "suggest" "area notes"
while IFS= read -r area; do
  if [ "$area" = "(root)" ]; then
    mapfile -t spec < <(awk -F/ 'NF == 1' <<<"$changed")
  else
    spec=("$area")
  fi

  mine="$(git log --fixed-strings --format='%ct %cr' "${author_args[@]}" "$mb" -- "${spec[@]}" | sort -rn)"
  total="$(grep -c . <<<"$mine" || true)"
  recent="$(awk -v c="$cutoff" '$1 >= c' <<<"$mine" | grep -c . || true)"
  last="$(head -1 <<<"$mine" | cut -d' ' -f2-)"
  [ -z "$last" ] && last="never"

  if [ "$recent" -ge 3 ]; then
    suggest="familiar"
  elif [ "$total" -gt 0 ]; then
    suggest="somewhat"
  else
    suggest="new"
  fi

  slug="${area//\//__}"
  note="$notes_dir/areas/$slug.md"
  if [ -f "$note" ]; then
    sha="$(sed -nE 's/^verified_at:[[:space:]]*([0-9a-f]+).*/\1/p' "$note" | head -1)"
    if [ -n "$sha" ] && git cat-file -e "$sha^{commit}" 2>/dev/null; then
      since="$(git rev-list --count "$sha..$mb" -- "${spec[@]}")"
      if [ "$since" -eq 0 ]; then
        notes="yes, current"
      else
        notes="yes, $since commit(s) since verified"
      fi
    else
      notes="yes, verified_at unknown"
    fi
  else
    notes="no"
  fi

  printf "%-32s %6s %7s  %-20s %-9s %s\n" "$area" "$total" "$recent" "$last" "$suggest" "$notes"
done <<<"$areas"

lang_fn='
function lang(f,   e) {
  if (f ~ /(^|\/)Dockerfile[^\/]*$/) return "Dockerfile"
  if (f !~ /\.[^.\/]+$/) return ""
  e = tolower(f); sub(/^.*\./, "", e)
  if (e ~ /^(ts|tsx|mts|cts)$/) return "TypeScript"
  if (e ~ /^(js|jsx|mjs|cjs)$/) return "JavaScript"
  if (e ~ /^(kt|kts)$/) return "Kotlin"
  if (e == "java") return "Java"
  if (e == "py") return "Python"
  if (e == "go") return "Go"
  if (e == "rb") return "Ruby"
  if (e == "rs") return "Rust"
  if (e == "cs") return "C#"
  if (e == "php") return "PHP"
  if (e == "swift") return "Swift"
  if (e ~ /^(scala|sc)$/) return "Scala"
  if (e == "dart") return "Dart"
  if (e ~ /^(ex|exs)$/) return "Elixir"
  if (e ~ /^(c|h)$/) return "C"
  if (e ~ /^(cc|cpp|cxx|hpp|hh)$/) return "C++"
  if (e ~ /^(m|mm)$/) return "Objective-C"
  if (e == "sql") return "SQL"
  if (e ~ /^(sh|bash|zsh)$/) return "Shell"
  if (e ~ /^(tf|tfvars|hcl)$/) return "Terraform"
  if (e == "groovy" || f ~ /\.gradle$/) return "Groovy"
  if (e == "vue") return "Vue"
  if (e == "svelte") return "Svelte"
  if (e == "proto") return "Protobuf"
  if (e ~ /^(graphql|gql)$/) return "GraphQL"
  return ""
}'

profile="$notes_root/reviewer.md"
pr_langs="$(awk "$lang_fn"' { l = lang($0); if (l != "") n[l]++ } END { for (l in n) printf "%s\t%d\n", l, n[l] }' <<<"$changed" | sort)"

echo
echo "== Languages in this change"
if [ -z "$pr_langs" ]; then
  echo "  none detected (config, docs or data files only)"
else
  mine_by_lang="$(git log --fixed-strings "${author_args[@]}" --format='@%h' --name-only "$mb" |
    awk "$lang_fn"' /^@/ { c = $0; next } NF { l = lang($0); if (l != "" && !seen[l, c]++) n[l]++ } END { for (l in n) printf "%s\t%d\n", l, n[l] }')"
  printf "%-14s %6s %11s  %s\n" "language" "files" "yours here" "profile ($profile)"
  while IFS=$'\t' read -r l files; do
    here="$(awk -F'\t' -v l="$l" '$1 == l { print $2 }' <<<"$mine_by_lang")"
    level="not set"
    if [ -f "$profile" ]; then
      found="$(awk -v l="$l" '{ line = tolower($0) } index(line, "- " tolower(l) ":") == 1 { sub(/^[^:]*:[[:space:]]*/, ""); print; exit }' "$profile")"
      [ -n "$found" ] && level="$found"
    fi
    printf "%-14s %6s %11s  %s\n" "$l" "$files" "${here:-0}" "$level"
  done <<<"$pr_langs"
fi

echo
echo "Suggestions come from commit history only: the reviewer decides the mode."
echo "History and area notes are per repository; only the language profile is shared across repositories."
