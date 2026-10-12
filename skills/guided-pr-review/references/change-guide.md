# Change guide

In Phase 3 the diff becomes a guide: sections grouped by purpose instead of by file, the core of the change first, and supporting changes set apart so they don't compete for attention. The idea comes from Linear's guided reviews (https://linear.app/docs/diffs). The rest of this skill still applies to it: the guide is a map, not a verdict, and the reviewer reads before you explain.

## Sections

A section is a set of hunks that serve one purpose, wherever they live. A new column, its migration, the query that reads it and the DTO field that exposes it can be one section, and one file can feed two sections when it carries two unrelated changes.

- Build sections from hunks, not files. `git diff -U0 --no-color <merge-base> HEAD -- <paths> | grep -E '^(\+\+\+ |@@ )'` lists every hunk with its line range, and the `@@` line names the enclosing function, which is often enough to group them.
- Atomic commits often map one to one onto sections. Use them when they do, and don't force it when they don't.
- Keep each section reviewable in one sitting, roughly 200 changed lines at most. Split a bigger one along the flow: entry point, logic, persistence.
- Tests go with the section they exercise. Shared test infrastructure (fixtures, factories, helpers) is supporting unless it changes what a test asserts.

## Core and supporting

**Core** sections change behavior, contracts or data. **Supporting** sections exist only so the core fits: wiring (dependency registration, routes, exports, imports), mechanical moves and renames, type plumbing that carries a value through layers without logic, formatting, generated code and lockfiles, and docs that restate the change.

Calling something supporting is a claim, and a behavior change inside a refactor is the classic hiding spot. So:

- Anything on a risk surface (the ones `pr_shape.sh` flags, plus money, personal data and concurrency) is core, whatever it looks like.
- Back the claim with evidence. `git diff -U0 -M <merge-base> HEAD -- <paths> | scripts/mechanical_check.sh` pairs removed and added lines by content, ignoring indentation, and lists every line that isn't a move or a rename. For a rename across many files, `git diff --word-diff=plain -U0 <merge-base> HEAD -- <paths>` shows whether each change is the same `[-old-]{+new+}` swap.
- Lines the check leaves over belong in a core section. A small "other changes" section is fine.
- When in doubt, it's core. The reviewer can promote any supporting section at any time.

## Order

1. The section with the core of the change: where the new behavior starts (handler, consumer, job, public function). Everything else hangs off it, and Google's guide also says to review the main part first.
2. Contracts and schemas the core introduces or changes, if they aren't already in it. They cost the most to change after merge.
3. The other core sections, following the flow outward from the core.
4. Supporting sections, last and together.

Reading the tests first, as a spec, is a valid alternative; offer it.

## Intent check

Link each core section to the intent items from Phase 1, the numbered list of what the PR says it does. Then report two lists:

- Sections the description doesn't explain. That can be scope creep, or just a description that's out of date.
- Intent items with no matching change, with what you searched.

Both are facts with references, not verdicts, and both are fair questions for the author.

## Presenting the guide (Phase 3)

| # | Section | Kind | Where | Lines | Risk | Intent |
|---|---|---|---|---|---|---|
| 1 | `retryPayment` and the gateway client | core | [src/payments/service.ts:130-168](src/payments/service.ts), [src/clients/gateway.ts:40-52](src/clients/gateway.ts) | 64 | money | 1 |
| 2 | `payments.idempotency_key` column | core | [db/migrations/0042_idempotency.sql:1-9](db/migrations/0042_idempotency.sql) | 9 | migration | 1 |
| 3 | Payments module wiring | supporting | [src/payments/module.ts:12-14](src/payments/module.ts) | 3 | | |

Titles depend on the try-first level. At `full`, a title names the code the section touches, not what that code now does, so the reviewer can still form their own reading in Phase 4. At `light` and `off`, titles can state the change ("Retries send an idempotency key").

Keep the table on one screen. On a large PR, list the core sections and summarize the supporting ones in one line.

## Walking a section (Phase 4)

Explain from the change to its consequences: what the section changes and which intent item it serves, then behavior before and after, then blast radius. Give every hunk both links, the repo reference and the GitHub diff line, as described in "Evidence links".

## Supporting sections

Walk them together after the core sections, one line each with its evidence:

```
3. Payments module wiring: registers RetryPolicy in PaymentsModule. mechanical_check: nothing beyond moves.
4. Rename OrderDto → OrderView (14 files): word-diff shows only that identifier, plus 2 other lines:
   - src/orders/mapper.ts:31 (base)  status: order.status,
   + src/orders/mapper.ts:31  status: order.status ?? "PENDING",
```

Leftover lines aren't supporting. Show them with references and move them into a core section if the reviewer agrees. The reviewer skims the rest, or promotes a section and walks it like a core one. In Phase 5, report supporting sections as skimmed with evidence, not as read.

## Structural diffs

When a line diff is noisy, these show what changed inside the lines:

- `git diff --word-diff=plain` marks changed words inside a line as `[-old-]{+new+}`.
- `git diff --color-moved=dimmed-zebra --color-moved-ws=allow-indentation-change` dims moved blocks in the reviewer's terminal. Suggest it for large refactors.
- difftastic, if installed, diffs by syntax and ignores formatting-only changes: `GIT_EXTERNAL_DIFF='difft --display inline --color never' git diff <merge-base> HEAD -- <path>`.

## Categories from .gitattributes

`pr_shape.sh` reads the `review-*` attributes Linear uses (`review-implementation`, `review-test`, `review-documentation`, `review-generated`, `review-agent-guidance`, `review-localization`, `review-assets`) and GitHub's `linguist-generated` and `linguist-documentation`. Setting one (`attr` or `attr=true`) puts the file in that category; unsetting it (`-attr` or `attr=false`) keeps the path heuristics from putting it there. Files with no attribute fall back to the heuristics.

When the heuristics get a repo wrong, such as a skills repo where `SKILL.md` is the implementation, suggest the team add the attributes. It fixes the categories here and in Linear at the same time:

```
skills/** review-implementation
tests/** review-test
docs/** review-documentation
generated/** linguist-generated=true
*.stories.tsx -review-test
```
