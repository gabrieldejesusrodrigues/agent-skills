---
name: tdd-lanes
description: Use when a change alters a business rule, calculation, permission/authorization check, state transition, money or data flow, or an error-handling contract — before writing implementation code. Also use when tests mirror the implementation or line coverage grows while rule bugs still ship. Skip for presentation-only changes, renames, mechanical refactors, one-liners, and prototypes.
---

# TDD Lanes — separate test authorship from implementation

**Principle:** the test author derives assertions from the spec and externally observable behavior, never from the implementation; the implementer satisfies the spec without weakening assertions. A ≠ B is the mechanism; the goal is contract-level tests that cover the *rules*, not just the lines.

**Use for** changes that alter a business rule, calculation, permission/authorization, state transition, money/data flow, or error contract. **Skip** presentation-only changes, renames/moves, mechanical refactors, config bumps, prototypes/spikes. Unsure whether a change is "behavior"? If a user, caller, or downstream system could notice it, it is.

**Modes:** *lightweight* (default) = Spec → A → B → orchestrator verifies. *strict* (money, auth, irreversible writes, migrations) = adds Lane C + one mutation check (*would the tests fail if a core branch, comparison, or source-selection were inverted or removed?*).

## Flow

1. **Spec (orchestrator).** Build the spec from real sources — the ticket's acceptance criteria, the PRD, documented current behavior. A rule you cannot trace to a source is a question for the PO/stakeholder, asked **before** spawning lanes; never invent one. Derive the case list (next section) and write each case with an ID, its input, and its expected *observable* outcome. State invariants that must always hold (idempotence, ordering, atomicity…) and non-goals.
2. **Context package (orchestrator).** Assemble the only thing Lane A will see: the spec with its case list; public signatures/types of the touched surface (when it already exists — for new surface, the tests define the contract); one existing test file as a convention example; relevant fixtures. Copy artifacts **verbatim**; never write your own prose about the code — curation is selection, not summarization, and a summary is where implementation strategy leaks. You read the implementation to plan the change; the package is where that contamination stops.
3. **Lane A — author** (fresh isolated agent — no prior reasoning from another lane, **no repo exploration**). Works only from the context package; anything missing returns as a batched request to the orchestrator — exploring for it is how implementation reaches the author's context, and context can't be un-seen. Writes one FAILING test per spec case, case ID in the test name. Minimal stubs only; no production logic. **Gap duty:** any input or situation the spec leaves undefined becomes a test marked `spec-gap` with a proposed expectation — never silently omitted, never a mid-run question. Lane A finishes the full sweep and reports every gap in batch; triage is the orchestrator's job, at Gate RED.
4. **Gate RED (orchestrator).** Diff spec case IDs against tests: every case has ≥1 test; every test maps to a case or a flagged `spec-gap`. Tests fail on assertions / not-implemented stubs — not on compile/import errors. Triage every `spec-gap` before continuing: answerable from the sources → fix the spec yourself; a business decision (the answer changes what a user, caller, or downstream system experiences) → ask the PO/user, carrying Lane A's proposed expectation *and* its alternative; pure engineering contract detail → decide and record it in the spec. The orchestrator invents business rules no more than Lane A does. Then regenerate affected tests via A.
5. **Lane B — implementer** (a different fresh isolated agent). **Satisfy the SPEC — not the tests, nor a presumed implementation strategy** — no hardcoded sentinels, test-only branches, or fixture hacks. Never change assertions: a wrong-looking assertion means a wrong spec → orchestrator fixes the spec and regenerates via A.
6. **Gate GREEN (orchestrator).** Full suite + type/lint + regenerated artifacts; green and no NEW lint/type errors vs baseline.
7. **Lane C (strict only).** Verify acceptance criteria against the code, not just by rerunning tests; run the mutation check.
8. **Commit on green**, co-authored.

## Deriving cases (spec step)

A rule without a test that violates it is an untested rule — line coverage is not rule coverage. REQUIRED per business rule in the spec:

- **1 satisfying case** — the rule holds; assert the happy outcome.
- **1 violating case** — the rule is broken; assert the *specific* refusal: which error, which fallback, what is NOT persisted/emitted.

Then walk this list top to bottom; each item that applies adds cases, each that doesn't is skipped without comment:

- **Boundaries** — every numeric/size limit a rule names → at the limit, just under, just over; plus empty, zero, negative, max where the type allows them.
- **Dependency failures** — one case per relevant failure mode of each external dependency (timeout, error response, empty result), asserting the declared fallback.
- **State** — invalid transitions rejected, valid ones asserted (only if the change is stateful).
- **Authorization** — the denied caller, not only the allowed one (only if the change touches permissions).
- **Idempotence / replay** — the same operation twice (only if it can be retried: queues, webhooks, payments).

### Example — case list for "apply discount coupon"

Rules from the ticket: coupon must be active; not expired; order total ≥ R$50; one use per customer.

| ID | Case | Expected |
|----|------|----------|
| C1 | valid coupon, order R$80 | discount applied, use recorded |
| C2 | inactive coupon | `COUPON_INACTIVE`, order unchanged |
| C3 | expired coupon | `COUPON_EXPIRED`, order unchanged |
| C4 | order R$49.99 | `MIN_ORDER_NOT_MET`, order unchanged |
| C5 | order exactly R$50.00 | discount applied (boundary) |
| C6 | second use, same customer | `COUPON_ALREADY_USED`, no double discount |
| C7 | coupon service timeout | declared fallback, no use recorded |
| C8 | same request replayed (retry) | one use recorded, not two |

C2–C6 exist because every rule got a violating case and every limit a boundary case — the checklist working, not extra rigor. If the ticket doesn't say what C7's fallback is, that's a PO question before lanes spawn, not a guess.

## Test rules (Lane A)

- **Contract-level, minimal-but-sufficient:** assert what's guaranteed externally — strong enough to catch wrong behavior, not so tight a harmless refactor breaks.
- **Externally observable** = return values, persisted state, emitted events, calls across stable boundaries (incl. "not called"). **Not** = internal ordering, private-helper coordination, incidental collaborator use.
- **One negative/control case** that would fail if the old behavior remained. To prove a value comes from X (not Y), give X a distinct sentinel *in the test* (sentinels in the implementation = the overfitting B is banned from).
- Update fixtures that assumed the old default/rule.

## Invariants

- **No lane redefines its own success criteria:** the author never *sees* the implementation (a curated package, not repo access); the implementer never weakens assertions; no lane self-approves; the orchestrator re-runs every gate itself.
- **A ≠ B (≠ C in strict mode).**
- **Commit only on green.** If a signature change breaks types in RED, bundle red+green into one verified commit — separation is by *authorship*, not a separate red commit.

## Orchestration

Same working tree for small changes; separate worktrees for large/risky ones (orchestrator merges in order). One spec → A → B (→ C) cycle per logical change.
