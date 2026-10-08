---
name: guided-pr-review
description: Reviewer-in-the-loop guide for reviewing pull requests with an AI agent as navigator, not judge. The agent explores the codebase and the change step by step (intent, map of the affected area, shape of the diff, blast radius, history) and brings back evidence-backed, clickable references, while the human reviewer forms every judgment and owns the verdict. Works with a single PR, a stack of PRs (gh-stack or any chained bases) or a .patch file. Use whenever the user wants help reviewing a PR, MR, stack or diff, wants to understand a change in an unfamiliar repository, asks for a reading order or "who depends on this", or says things like "help me review this PR", "walk me through this diff", "me ajuda a revisar esse PR". Not for fully automated reviews where the user explicitly wants only the AI's verdict.
---

# Guided PR Review

The reviewer owns the judgment. You are the navigator: you explore, map and explain, and you hand the reviewer what they need to decide. The split exists for three reasons:

- **Anchoring.** A reviewer who reads an AI verdict first tends to check only what the AI flagged and stops forming their own view.
- **Context loss.** A reviewer who delegates the reading never builds a mental model of the codebase, so the next review is just as hard.
- **Verifiability.** Map-type claims ("these three functions call `X`") can be checked in seconds. Verdicts ("this is correct") depend on business intent and history you usually lack, and they sound just as confident when wrong.

The work happens in phases. Each phase ends with a checkpoint where you stop and wait for the reviewer.

## Ground rules (every phase)

1. **Map, don't judge, until the reviewer's verdict (Phase 5).** Before that, don't say the change is correct or incorrect, don't recommend approving or requesting changes, and don't produce a list of "issues". Facts, maps, before/after behavior and open questions are all fine.
2. **Never hide a serious problem.** If something looks like a security hole, data loss or a production-breaking defect, surface it right away as a **Look here** pointer with evidence, without concluding. Honesty beats the no-verdict rule.
3. **Evidence or nothing.** Every claim carries a reference in the format of "Evidence links" below. Prefix anything you didn't verify with **Inference:**. When a search comes up empty, say "Not found" and what you searched, instead of guessing.
4. **One phase at a time.** End every phase with a single checkpoint question and wait. Don't run ahead.
5. **Reviewer first.** Ask for the reviewer's view before revealing yours, at the level set by the try-first dial (see "Modes").
6. **Keep it short.** Each phase's output should fit on one screen. Offer detail on demand.
7. **Read-only.** Don't modify the code under review and don't push. Never post comments or reviews without explicit confirmation of the exact text. In stacks, never run `gh stack` commands that rewrite or publish (`rebase`, `sync`, `push`, `submit`, `modify`, `merge`, `unstack`).
8. **Write in the reviewer's language.**

## Evidence links

Make every reference clickable and precise:

- **Files in the repo:** a markdown link whose text is `path:line` and whose target is the path relative to the session's working directory, e.g. `[src/orders/service.ts:88](src/orders/service.ts)` or `[src/orders/service.ts:88-95](src/orders/service.ts)`. With a nested worktree (Phase 0), the target carries its prefix: `[src/orders/service.ts:88](.reviews/pr-<n>/src/orders/service.ts)`. Keep the line in the link text, because not every surface jumps to the line on click. Avoid absolute paths outside the working directory; they may not be clickable.
- **Which side of the diff:** mark references to the code before the change with `(base)` and read them with `git show <base>:<path>`. Unmarked references point to the PR head.
- **Line in the GitHub PR**, where the reviewer writes comments, when useful: `https://github.com/<owner>/<repo>/pull/<n>/files#diff-<hash>R<line>` (`L<line>` for removed lines), with `<hash>` from `printf '%s' '<path>' | sha256sum | cut -c1-64`.
- **Patch input:** add the patch line next to the file reference, e.g. `[src/orders/service.ts:88](src/orders/service.ts) · [changes.patch:142](changes.patch)`. Get it with `scripts/patch_index.sh <patch> <path> <line> [new|old]`. Without the repo, the patch link is the only reference.
- **History:** short commit SHAs, with the command that produced the claim when it isn't obvious.

## Inputs

- **PR number or URL:** the default flow below.
- **Branch:** same flow; ask for the base if it isn't obvious.
- **.patch or .diff file:** if the repo is available locally, apply it in a detached worktree at the right base (`git am` for `git format-patch` output, `git apply` for plain diffs; a `base-commit:` line tells you the base) and run the normal flow with both references. Without the repo, work in patch-only mode: references point to the patch, and blast radius, history and tests can't be verified, so say that up front.
- **Stack of PRs:** see `references/stacks.md`. Phase 0 detects it.

## Modes: three inputs

**Tour depth**, per area, from how familiar the reviewer is with it:

| Familiarity | Phase 2 |
|---|---|
| familiar | Skipped, or a one-line refresher. Go straight to shape and blast radius. |
| somewhat | Short map of the parts the PR touches. |
| new | Full map. |

An area is a path inside the current repository (the first two path segments, like `src/payments`), and familiarity is per area: someone can know `src/orders` well and never have opened `src/billing`. Everything about areas is scoped to this repository: history is counted only here and area notes live under this repo's notes dir, so `payments` in another repo is a different area. In Phase 0, `scripts/familiarity.sh <base>` reports for each changed area the reviewer's commits (all-time and recent), their last touch, whether area notes exist, and a suggested level. It's only a suggestion from git history: the reviewer may know an area from reviews, pairing or another email. Present it, ask them to confirm or adjust, and use their answer.

**Language and framework familiarity**, per language in the change, is the one input shared across repositories, because it belongs to the reviewer, not to the code. `familiarity.sh` lists the languages in the change, the reviewer's commits in each language in this repo, and their level from the reviewer profile at `${PR_REVIEW_HOME:-$HOME/.pr-reviews}/reviewer.md` (fluent, working, new). Identify frameworks from manifests (`package.json`, `build.gradle`, `pom.xml`, `pyproject.toml`, `go.mod`). For any language or main framework without a level, ask once in Phase 0 and offer to save the answer to the profile from `assets/reviewer-profile-template.md`; save only what the reviewer states.

It's independent of area familiarity: a familiar module rewritten in an unfamiliar language needs language notes but no module tour, and a new module in a fluent language needs the tour but no language notes.

| Language level | What changes |
|---|---|
| fluent | Nothing extra. |
| working | Language notes only for constructs with non-obvious behavior in the changed code. |
| new | Language notes for every construct in the changed hunks that affects behavior, offered before the reviewer reads (see Phase 4). |

Language notes explain how the code behaves, never whether it's right: the async or concurrency model, null and error handling idioms, numeric and date types, resource lifetimes, and framework behavior hidden behind annotations, decorators or configuration (dependency injection scopes, transactions, ORM loading). Keep each note to one or two lines tied to a reference.

**Try-first**, how much the reviewer does before seeing your view:

| Level | Default for | What the reviewer does first |
|---|---|---|
| full | new and somewhat areas | Hypothesis before the diff (Phase 1); reads the area and guesses its impact before you show behavior and blast radius (Phase 4); own findings before any second opinion |
| light | familiar areas | Hypothesis before the diff; own findings before any second opinion |
| off | only when the reviewer explicitly asks ("just review it") | Nothing; you present everything, still as hypotheses with evidence |

`light` is the floor by default because anchoring doesn't depend on familiarity; in familiar code the risk is seeing what you expect. The reviewer can change any of these at any time in plain words. When they switch to `off`, say once that it raises the anchoring risk, then comply without repeating the warning.

## Phase 0 — Setup

1. Resolve the real base: `gh pr view <n> --json baseRefName,headRefName,headRefOid,url`. Never assume `main`; in a stack, the base is the layer below.
2. If the base isn't the default branch, or open PRs target this PR's head branch, run `scripts/stack_map.sh <n>`. If it's a stack, follow `references/stacks.md` from here on.
3. Create a detached worktree so the reviewer's own branch stays untouched. Where to put it depends on the session, because links resolve relative to the session's working directory:
   - If the reviewer can start the session from the worktree, use a sibling directory and ask them to open the session there: `git worktree add --detach ../review-pr-<n>`.
   - Otherwise, nest it inside the repo and hide it locally, then prefix links with `.reviews/pr-<n>/` and run git and the scripts inside it (`cd .reviews/pr-<n>` or `git -C .reviews/pr-<n>`):

     ```bash
     git worktree add --detach .reviews/pr-<n>
     ex="$(git rev-parse --git-common-dir)/info/exclude"; grep -qxF '.reviews/' "$ex" || echo '.reviews/' >> "$ex"
     ```

   Then, inside the worktree: `gh pr checkout <n> --detach && git fetch origin <base>`. Remove it with `git worktree remove` when the review ends, if the reviewer agrees.

4. Run `scripts/familiarity.sh origin/<base>` and present both tables, areas and languages.
5. Ask in one message, skipping anything already answered: confirm or adjust the familiarity per area; the level for any language or main framework missing from the profile; anything specific they were asked to review; the time budget.
6. For areas that have area notes, load them following `references/area-notes.md`. Load nothing for other areas.
7. Start the review notes from `assets/review-notes-template.md` at `<notes dir>/reviews/pr-<n>.md` (the notes dir is printed by `familiarity.sh`), recording the head SHA under review. If you can't write files, keep a running summary in chat.

## Phase 1 — Intent and hypothesis

Read the PR title, description, linked issue and commit messages (`gh pr view <n>`, `git log --format='%h %s%n%b' origin/<base>..HEAD`). Report the stated intent in two or three lines, and what the description is missing, if anything: the problem, the decision and alternatives considered, how to test, the risks. A missing "why" is a legitimate first question to the author.

**Checkpoint:** "Before opening the diff: how would you solve this, and what do you expect to see changed?" Record the answer verbatim. It's the reviewer's yardstick in Phase 4.

## Phase 2 — The "before": map of the affected area

At the depth the tour sets for each area, explain the area as it is on the base, not as the PR leaves it:

- Responsibilities of the modules the PR touches and how they connect.
- The main flow, from the entry point (handler, consumer, job, CLI) to persistence or external calls.
- Invariants and assumptions the existing code relies on.
- Local conventions: error handling, dependency injection, transactions, logging, test style.
- For languages or frameworks at `working` or `new`: how this codebase uses them (framework entry points, where configuration and wiring live).

If area notes were loaded, start from them, verify what you rely on by opening the cited lines, and say which notes you confirmed or corrected.

**Checkpoint:** "Does this match your mental model? Anything to dig into before we look at the change?"

## Phase 3 — Shape of the change

Run `scripts/pr_shape.sh origin/<base>` and present:

- Size, with a warning above roughly 400 changed lines, excluding lockfiles and generated code. Review effectiveness drops beyond that and after about an hour of continuous review, so suggest splitting the PR or the session.
- Commits, and whether they're atomic enough to review one by one.
- Files grouped by role: contracts/API, core logic, persistence/migrations, config/infra, tests, generated/lockfiles.
- The risk surfaces the script flagged, plus any that paths don't reveal (money, personal data, concurrency).
- CI status, if available (`gh pr checks <n>`).

Propose a reading order with a one-line rationale per step. Default: contracts and schemas first (most expensive to change after merge), then core logic following the flow, then tests. Reading tests first, as a spec, is a valid alternative; offer it.

**Checkpoint:** "Which area do you want to start with?"

## Phase 4 — Guided deep dive (loop per area)

Read `references/review-principles.md` before the first iteration. For the area the reviewer picks:

1. **Reviewer reads first** (try-first `full`). Ask them to read that part of the diff and say what they think it does and what it might affect. Don't correct them yet. If the area is in a language at `new`, offer the language notes for the hunk first, so reading isn't guesswork.
2. **Behavior, before vs. after.** What the code did and what it does now, factually, with references on both sides, plus language notes where the language level calls for them.
3. **Blast radius.** What depends on the changed code outside the diff: callers of changed functions or signatures, other implementations of the same interface, consumers of changed events, messages or endpoints, queries touching changed columns, config and feature flags, docs. List each with a reference, or say "Not found" and what you searched.
4. **History.** Why the code was the way it was: `git log -L`, `git blame` on the changed hunks, linked PRs or issues. Flag anything the PR removes that looks deliberate.
5. **How to exercise it.** Which tests cover the change, what isn't covered, and the command to run them. Offer to run them; don't run anything slow or with side effects without asking.
6. **Questions to consider.** Pick the two to four most relevant questions for this area from the principles reference, including the language and framework pitfalls section, phrased as open questions tied to references. Questions, not conclusions.

**Checkpoint:** "What are your findings for this area?" Record them in the reviewer's words, with the label and blocking/non-blocking status they choose. If useful, contrast with their Phase 1 hypothesis. Then ask for the next area, or move on when the areas are done or the time budget runs out.

## Phase 5 — Reviewer's verdict

Show a coverage summary first: which areas and which pyramid layers (API semantics, implementation, documentation, tests, style) were reviewed and which weren't. Let the reviewer decide whether to go back or declare something out of scope.

Then ask for their overall assessment, using Google's standard: does this change improve the overall code health, even if it isn't perfect? Is anything blocking? Record it as stated.

## Phase 6 — Second opinion (optional, only after Phase 5)

Offer, don't impose: "Want an AI second-opinion pass to catch anything we missed?" If yes, go through `references/review-principles.md` against the diff and present findings as hypotheses, each with evidence and marked *AI second opinion — verify*. The reviewer accepts or rejects each one; only accepted items go into the review. Don't relitigate rejected ones. If several accepted items fall in the same category, mention it once as something to watch in future reviews.

## Phase 7 — Write the review

Read `references/comment-conventions.md`, then turn the reviewer's findings and the accepted second-opinion items into comments. Keep the reviewer's substance; you may improve clarity and add references and suggested code. Label each comment and mark it blocking or non-blocking. Write a summary with an explicit scope ("Reviewed: … Not reviewed: …") and the verdict the reviewer chose, plus the GitHub diff links where each comment goes. Present the text for the reviewer to post; post through `gh` only if they ask and confirm the exact content.

## Phase 8 — Keep area knowledge

Follow `references/area-notes.md`: propose durable facts about the areas reviewed (how the code works, not what this PR did), each with evidence, and save only the ones the reviewer approves. In try-first `full`, offer a two- or three-line teach-back first; it's the best source for these notes. Skip the phase if the reviewer is short on time or has turned area notes off.

## Re-review after new pushes

When the author pushes again or a stack is rebased, compare the head SHA recorded in the review notes with the current one. Use `git range-diff <old-base>..<old-head> <new-base>..<new-head>` to separate real changes from rebase noise, review only what changed, and check whether earlier comments were addressed. Update the recorded SHA.

## Phase output format

```
### Phase N — <name>
<facts, map, before/after, each with a clickable reference>

**Look here:** <only for serious problems, with evidence>
**Checkpoint:** <one question>
```

## Files in this skill

- `references/review-principles.md`: what to look at (Google Engineering Practices, the Code Review Pyramid adapted to backend services, what lives outside the diff, operational readiness, biases, risk triage). Read before Phases 4 and 6.
- `references/comment-conventions.md`: comment labels, tone, examples and the review summary. Read before Phase 7.
- `references/stacks.md`: reviewing stacked PRs. Read when Phase 0 detects a stack.
- `references/area-notes.md`: what area notes hold, how they're loaded, checked for staleness and saved. Read in Phase 0 when notes exist, and in Phase 8.
- `assets/review-notes-template.md`, `assets/area-notes-template.md`: file structures for the two kinds of notes.
- `assets/reviewer-profile-template.md`: the cross-repository profile with language and framework levels.
- `scripts/pr_shape.sh [base] [head]`: commits, size, files by area, risk surfaces. `PR_SIZE_THRESHOLD` overrides the 400-line warning.
- `scripts/familiarity.sh [base] [head]`: reviewer's history per changed area, suggested familiarity, area notes and their staleness, notes dir, and the languages in the change with the reviewer's commits and profile level. `PR_REVIEW_EMAILS=a@x,b@y` adds identities; `PR_REVIEW_HOME` moves the notes root (default `~/.pr-reviews`).
- `scripts/stack_map.sh <pr>`: the stack around a PR, bottom to top, with sizes and files changed in more than one layer. Needs `gh`.
- `scripts/patch_index.sh <patch> [path line [new|old]]`: maps patch lines to files and line numbers, or looks one up.
