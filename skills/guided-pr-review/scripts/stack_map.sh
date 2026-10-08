#!/usr/bin/env bash
set -euo pipefail

pr="${1:?usage: stack_map.sh <pr-number>}"
max_layers="${STACK_MAX_LAYERS:-30}"

trunk="$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)"

pr_field() { gh pr view "$1" --json "$2" --jq ".$2"; }

below_of() {
  gh pr list --head "$1" --state all --json number,state \
    --jq 'sort_by(.state != "OPEN") | .[0].number // empty'
}

above_of() {
  gh pr list --base "$1" --state open --json number --jq '.[].number'
}

chain=("$pr")
notes=()

cur="$pr"
for _ in $(seq "$max_layers"); do
  base="$(pr_field "$cur" baseRefName)"
  [ "$base" = "$trunk" ] && break
  below="$(below_of "$base")"
  if [ -z "$below" ]; then
    notes+=("bottom #$cur targets '$base', which is not trunk and has no PR")
    break
  fi
  case " ${chain[*]} " in *" $below "*) notes+=("cycle detected at #$below"); break ;; esac
  chain=("$below" "${chain[@]}")
  cur="$below"
done

cur="$pr"
for _ in $(seq "$max_layers"); do
  head_ref="$(pr_field "$cur" headRefName)"
  mapfile -t above < <(above_of "$head_ref")
  [ "${#above[@]}" -eq 0 ] && break
  if [ "${#above[@]}" -gt 1 ]; then
    notes+=("#$cur has ${#above[@]} open PRs on top (${above[*]/#/#}): the stack branches; following #${above[0]}")
  fi
  case " ${chain[*]} " in *" ${above[0]} "*) notes+=("cycle detected at #${above[0]}"); break ;; esac
  chain+=("${above[0]}")
  cur="${above[0]}"
done

if [ "${#chain[@]}" -eq 1 ] && [ "$(pr_field "$pr" baseRefName)" = "$trunk" ]; then
  echo "#$pr targets $trunk directly and has no open PR on top: not a stack."
  exit 0
fi

echo "== Stack (bottom → top), trunk: $trunk"
files_tmp="$(mktemp)"
trap 'rm -f "$files_tmp"' EXIT
i=0
for n in "${chain[@]}"; do
  i=$((i + 1))
  line="$(gh pr view "$n" --json number,state,isDraft,baseRefName,headRefName,additions,deletions,title \
    --jq '"#\(.number) \(.state)\(if .isDraft then " (draft)" else "" end)  \(.baseRefName) ← \(.headRefName)  +\(.additions)/-\(.deletions)  \(.title)"')"
  marker=""
  [ "$n" = "$pr" ] && marker="   ← requested"
  printf "%2d. %s%s\n" "$i" "$line" "$marker"
  gh pr view "$n" --json files --jq '.files[].path' | sed "s|\$|	#$n|" >>"$files_tmp"
done

echo
echo "== Files changed in more than one layer (possible churn or a split worth checking)"
churn="$(awk -F'\t' '{ seen[$1] = seen[$1] " " $2; count[$1]++ } END { for (f in count) if (count[f] > 1) printf "  %s:%s\n", f, seen[f] }' "$files_tmp" | sort)"
if [ -n "$churn" ]; then
  echo "$churn"
else
  echo "  none"
fi

if [ "${#notes[@]}" -gt 0 ]; then
  echo
  echo "== Notes"
  printf "  %s\n" "${notes[@]}"
fi
