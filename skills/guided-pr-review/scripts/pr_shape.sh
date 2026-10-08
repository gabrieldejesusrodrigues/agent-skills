#!/usr/bin/env bash
set -euo pipefail

base="${1:-origin/main}"
head="${2:-HEAD}"
export PR_SIZE_THRESHOLD="${PR_SIZE_THRESHOLD:-400}"
export SKIM_RE='(^|/)(package-lock\.json|npm-shrinkwrap\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Pipfile\.lock|uv\.lock|Cargo\.lock|go\.sum|composer\.lock|Gemfile\.lock|gradle\.lockfile)$|(^|/)(dist|build|vendor|generated|__generated__)/|\.min\.(js|css)$|\.snap$|\.pb\.go$|_pb2\.py$'

mb="$(git merge-base "$base" "$head")"
numstat="$(git diff --numstat --no-renames "$mb" "$head")"
changed="$(git diff --name-only --no-renames "$mb" "$head")"

if [ -z "$changed" ]; then
  echo "No changes between $base and $head. Is the PR branch checked out, and is $base the right base?"
  exit 0
fi

echo "== Range: $base (merge base $(git rev-parse --short "$mb")) .. $head"
echo
echo "== Commits"
git log --no-merges --format='%h %s' "$mb..$head"
echo
echo "== Size"
git diff --shortstat "$mb" "$head"
awk -F'\t' '
  $1 == "-" { bin++; next }
  $3 ~ ENVIRON["SKIM_RE"] { skim += $1 + $2; next }
  { review += $1 + $2 }
  END {
    printf "Lines to review: %d (excluded: %d in lockfiles/generated, %d binary files)\n", review, skim, bin
    if (review > ENVIRON["PR_SIZE_THRESHOLD"] + 0)
      printf "WARNING: above %d changed lines. Consider splitting the PR or the review session.\n", ENVIRON["PR_SIZE_THRESHOLD"]
  }' <<<"$numstat"
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
flag "lockfiles/generated (skim)" "$SKIM_RE"

if grep -Eiq -- '(test|spec|__tests__)' <<<"$changed"; then
  flag "tests" '(test|spec|__tests__)'
else
  echo "[tests]"
  echo "  no test files changed: check how the change is covered"
fi
