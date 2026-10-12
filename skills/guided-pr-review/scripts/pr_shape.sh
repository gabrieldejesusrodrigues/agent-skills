#!/usr/bin/env bash
set -euo pipefail

base="${1:-origin/main}"
head="${2:-HEAD}"
export PR_SIZE_THRESHOLD="${PR_SIZE_THRESHOLD:-400}"
export GENERATED_RE='(^|/)(package-lock\.json|npm-shrinkwrap\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Pipfile\.lock|uv\.lock|Cargo\.lock|go\.sum|composer\.lock|Gemfile\.lock|gradle\.lockfile)$|(^|/)(dist|build|vendor|generated|__generated__)/|\.min\.(js|css)$|\.snap$|\.pb\.go$|_pb2\.py$'
export AGENT_RE='(^|/)(AGENTS|CLAUDE|GEMINI)\.md$|(^|/)\.(claude|cursor|windsurf)/|(^|/)\.(cursorrules|windsurfrules)$|(^|/)\.github/(copilot-instructions\.md|instructions/)'
export TEST_RE='(^|/)(__tests__|tests?|spec|e2e|testdata|fixtures?)/|[._-](test|spec|e2e)s?\.[A-Za-z0-9]+$|(^|/)test_[^/]*\.py$|Tests?\.(java|kt|kts|cs|swift|scala)$'
export DOC_RE='(^|/)docs?/|\.(md|mdx|rst|adoc)$|(^|/)(README|CHANGELOG|CONTRIBUTING|LICENSE|NOTICE)[^/]*$'
export L10N_RE='(^|/)(locales?|i18n|l10n|translations?)/|\.(po|pot|xliff|xlf|strings|stringsdict|arb)$|(^|/)messages(_[A-Za-z]+)+\.properties$'
export ASSET_RE='\.(png|jpe?g|gif|webp|avif|svg|ico|bmp|tiff?|woff2?|ttf|otf|eot|mp3|mp4|wav|ogg|webm|mov|pdf)$'

mb="$(git merge-base "$base" "$head")"
numstat="$(git diff --numstat --no-renames "$mb" "$head")"
changed="$(git diff --name-only --no-renames "$mb" "$head")"

if [ -z "$changed" ]; then
  echo "No changes between $base and $head. Is the PR branch checked out, and is $base the right base?"
  exit 0
fi

review_attrs=(review-generated linguist-generated review-agent-guidance review-test review-documentation
  linguist-documentation review-localization review-assets review-implementation)
attrs="$(git check-attr --source "$head" --stdin "${review_attrs[@]}" <<<"$changed" 2>/dev/null ||
  git check-attr --stdin "${review_attrs[@]}" <<<"$changed" 2>/dev/null || true)"

categories="$(awk '
  BEGIN {
    nc = split("generated agent-guidance test documentation localization assets implementation", order, " ")
    cat_of["review-generated"] = "generated"; cat_of["linguist-generated"] = "generated"
    cat_of["review-agent-guidance"] = "agent-guidance"
    cat_of["review-test"] = "test"
    cat_of["review-documentation"] = "documentation"; cat_of["linguist-documentation"] = "documentation"
    cat_of["review-localization"] = "localization"
    cat_of["review-assets"] = "assets"
    cat_of["review-implementation"] = "implementation"
    re["generated"] = ENVIRON["GENERATED_RE"]; re["agent-guidance"] = ENVIRON["AGENT_RE"]
    re["test"] = ENVIRON["TEST_RE"]; re["documentation"] = ENVIRON["DOC_RE"]
    re["localization"] = ENVIRON["L10N_RE"]; re["assets"] = ENVIRON["ASSET_RE"]
  }
  FILENAME == ARGV[1] {
    if (!match($0, /: [a-z-]+: [^:]*$/)) next
    path = substr($0, 1, RSTART - 1)
    split(substr($0, RSTART + 2), kv, ": ")
    c = cat_of[kv[1]]
    if (kv[2] == "set" || kv[2] == "true") yes[path, c] = 1
    else if (kv[2] == "unset" || kv[2] == "false") no[path, c] = 1
    next
  }
  NF {
    for (i = 1; i <= nc; i++) if (($0, order[i]) in yes) { print $0 "\t" order[i] "\tattr"; next }
    for (i = 1; i < nc; i++) if (!(($0, order[i]) in no) && $0 ~ re[order[i]]) { print $0 "\t" order[i] "\tpath"; next }
    print $0 "\timplementation\tdefault"
  }' <(printf '%s\n' "$attrs") <(printf '%s\n' "$changed"))"

echo "== Range: $base (merge base $(git rev-parse --short "$mb")) .. $head"
echo
echo "== Commits"
git log --no-merges --format='%h %s' "$mb..$head"
echo
echo "== Size by review category (.gitattributes review-*/linguist-* first, then path heuristics)"
git diff --shortstat "$mb" "$head"
awk -F'\t' '
  FILENAME == ARGV[1] { cat[$1] = $2; next }
  NF >= 3 {
    c = ($3 in cat ? cat[$3] : "implementation")
    files[c]++
    if ($1 == "-") { bin++; next }
    lines[c] += $1 + $2
  }
  END {
    n = split("implementation test documentation agent-guidance localization assets generated", order, " ")
    for (i = 1; i <= n; i++)
      if (files[order[i]]) printf "  %-15s %6d lines  %3d files\n", order[i], lines[order[i]], files[order[i]]
    for (c in lines) if (c != "generated") review += lines[c]
    printf "Lines to review: %d, of which implementation: %d (excluded: %d in generated/lockfiles, %d binary files)\n",
      review, lines["implementation"], lines["generated"], bin
    if (review > ENVIRON["PR_SIZE_THRESHOLD"] + 0)
      printf "WARNING: above %d lines to review. Consider splitting the PR or the review session.\n", ENVIRON["PR_SIZE_THRESHOLD"]
  }' <(printf '%s\n' "$categories") <(printf '%s\n' "$numstat")
echo
echo "== Files outside implementation (attr: set in .gitattributes; path: heuristic, override with review-* attributes)"
outside="$(awk -F'\t' '$2 != "implementation" { printf "  [%s] %s (%s)\n", $2, $1, $3 }' <<<"$categories" | sort)"
echo "${outside:-  none}"
echo
echo "== Files by area (first two path segments)"
awk -F'\t' '
  NF >= 3 {
    n = split($3, p, "/")
    area = (n > 2 ? p[1] "/" p[2] : (n == 2 ? p[1] : "(root)"))
    lines[area] += ($1 == "-" ? 0 : $1 + $2)
    files[area]++
  }
  END { for (a in lines) printf "%6d lines  %3d files  %s\n", lines[a], files[a], a }' <<<"$numstat" | sort -rn
echo
echo "== Risk surfaces (path heuristics: verify, not exhaustive)"

flag() {
  local label="$1" re="$2" hits
  hits="$(grep -Ei -- "$re" <<<"$changed" || true)"
  if [ -n "$hits" ]; then
    echo "[$label]"
    sed 's/^/  /' <<<"$hits"
  fi
}

flag "contracts/schemas" '(openapi|swagger|asyncapi|\.proto$|\.graphql$|\.avsc$|schema|contract|(^|/)dtos?/|dto\.)'
flag "migrations/data" '(migrat|flyway|liquibase|alembic|\.sql$)'
flag "auth/security" '(auth|security|permission|polic(y|ies)|acl|rbac|token|jwt|oauth|crypto|secret|password)'
flag "config/infra" '(\.env|config|settings|Dockerfile|docker-compose|helm|k8s|kubernetes|terraform|\.tf$|\.tfvars$)'
flag "ci/cd" '(\.github/workflows|\.gitlab-ci|Jenkinsfile|cloudbuild|\.circleci|azure-pipelines)'
flag "dependencies" '((^|/)package\.json$|go\.mod$|pom\.xml$|build\.gradle|requirements[^/]*\.txt$|pyproject\.toml$|Cargo\.toml$|Gemfile$|composer\.json$)'

if ! awk -F'\t' '$2 == "test" { found = 1 } END { exit !found }' <<<"$categories"; then
  echo "[tests]"
  echo "  no test files changed: check how the change is covered"
fi
