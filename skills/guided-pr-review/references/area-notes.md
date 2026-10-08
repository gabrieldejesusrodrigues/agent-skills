# Area notes

What carries over between reviews in the same repo is how the code works, not what a particular PR was about. Two PRs in the same repo can have nothing in common; two PRs in the same module share the module. So there are two separate stores, and only one of them is ever reused.

| Store | Location | Holds | Reused? |
|---|---|---|---|
| Review notes | `<notes dir>/reviews/pr-<n>.md` (or `stack-<n>.md`) | Intent, the reviewer's hypothesis, findings, verdict, comments, head SHA reviewed | Only when re-reviewing the same PR |
| Area notes | `<notes dir>/areas/<area>.md` | Durable facts about one area: responsibilities, main flows, invariants, conventions, gotchas | Loaded only for areas a new PR touches |

`<notes dir>` is `${PR_REVIEW_HOME:-$HOME/.pr-reviews}/<owner>__<repo>`, printed by `scripts/familiarity.sh`. Area notes never cross repositories: `payments` in another repo is a different area with its own notes. The only cross-repository file is the reviewer profile (`${PR_REVIEW_HOME:-$HOME/.pr-reviews}/reviewer.md`), which holds language and framework levels, not knowledge about any codebase. The area is the same grouping the scripts use (first two path segments), with `/` replaced by `__` in the file name. The files live outside the repository and are never committed.

If the reviewer sets `PR_REVIEW_AREA_NOTES=off` or asks not to use them, skip loading and saving entirely.

## What qualifies

The test: would this still be true and useful for an unrelated PR in the same area?

- Fits: "All outbound calls to the billing provider go through `BillingClient`, which retries three times with backoff ([src/clients/billing.ts:40](src/clients/billing.ts))."
- Fits: "Handlers never open transactions; the service layer does ([src/orders/service.ts:12](src/orders/service.ts))."
- Doesn't fit: "PR #123 moves validation into the repository." That's PR-specific and belongs in the review notes.
- Doesn't fit: anything without a code reference, or anything only you believe and the reviewer didn't confirm.

## Loading (Phase 0 and Phase 2)

1. `familiarity.sh` shows which changed areas have notes and how many commits touched each area since its `verified_at` commit.
2. Read only the notes for areas the PR touches.
3. Present them as "notes from earlier reviews": a starting point to confirm, not truth. Before relying on a fact, open the cited line.
4. If the area changed since `verified_at`, say how many commits, check the facts those commits could affect (`git log --oneline <verified_at>..<merge-base> -- <paths>`), and propose corrections or removals for facts that no longer hold.
5. Notes never replace reading the code the PR changes.

## Saving (Phase 8)

1. Propose candidate facts per area, drawn from the Phase 2 map and the reviewer's teach-back, each with a reference.
2. The reviewer approves, edits or drops each one. Save only what they approved.
3. Merge into the existing file from `assets/area-notes-template.md`: update facts that changed, remove facts that were contradicted, keep the rest.
4. Set `verified_at` to the merge-base SHA of this review and `updated` to today.
