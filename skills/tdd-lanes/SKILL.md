---
name: tdd-lanes
description: Use when a non-trivial logic / behavior / business-rule change needs contract-level tests not derived from the implementation. A test author (no implementation context) writes failing tests from a spec; a DIFFERENT implementer makes them pass without weakening the assertions. Stack-agnostic. Modes — lightweight (A→B→verify) and strict (+ independent verifier + mutation check).
---

# TDD Lanes — separate test authorship from implementation

**Principle:** the test author derives assertions from the spec + externally observable behavior, never from the implementation; the implementer satisfies the spec without weakening assertions. A ≠ B is the mechanism; the goal is contract-level, non-overfit tests decoupled from the implementation.

**Use for** non-trivial logic / behavior / business-rule changes. **Skip** mechanical refactors, renames/moves, one-liners, prototypes.

**Modes:** *lightweight* (default) = A → B → orchestrator verifies. *strict* (high-stakes) = adds Lane C + one mutation check (*would the tests fail if a core branch / comparison / source-selection were inverted or removed?*).

## Flow

1. **Spec (orchestrator).** Inputs/outputs, cases, edge/error modes, invariants that must always hold (idempotence, ordering, atomicity…), non-goals. Sanity-check it for ambiguity, observable-not-internal behavior, and backward-compat before spawning lanes — a wrong spec just yields good tests for the wrong requirement.
2. **Lane A — author** (fresh isolated agent — no prior reasoning from another lane). Writes every case as a FAILING test. MAY read public interfaces, existing tests, fixtures, docs; **must NOT derive assertions from the implementation — not even via adjacent-code exploration.** Minimal stubs only; no production logic.
3. **Gate RED.** Tests fail on assertions / not-implemented stubs — not on compile/import errors.
4. **Lane B — implementer** (a different fresh isolated agent). **Satisfy the SPEC — not the tests, nor a presumed implementation strategy** — no hardcoded sentinels, test-only branches, or fixture hacks. Don't change assertions (any change needs orchestrator approval + rationale; prefer fixing the spec → regenerate via A).
5. **Gate GREEN.** Full suite + type/lint + regenerated artifacts; green and no NEW lint/type errors vs baseline.
6. **Lane C (strict only).** Verify acceptance criteria against the code, not just by rerunning tests.
7. **Commit on green**, co-authored.

## Test rules (Lane A)

- **Contract-level, minimal-but-sufficient:** assert what's guaranteed externally — strong enough to catch wrong behavior, not so tight a harmless refactor breaks.
- **Externally observable** = return values, persisted state, emitted events, calls across stable boundaries (incl. "not called"). **Not** = internal ordering, private-helper coordination, incidental collaborator use.
- **One negative/control case** that would fail if the old behavior remained. To prove a value comes from X (not Y), give X a distinct sentinel *in the test* (sentinels in the implementation = the overfitting B is banned from).
- Update fixtures that assumed the old default/rule.

## Invariants

- **No lane redefines its own success criteria:** author never reads the impl; implementer never weakens assertions; no lane self-approves; the orchestrator re-runs every gate itself.
- **A ≠ B (≠ C in strict mode).**
- **Commit only on green.** If a signature change breaks types in RED, bundle red+green into one verified commit — separation is by *authorship*, not a separate red commit.

## Orchestration

Same working tree for small changes; separate worktrees for large/risky ones (orchestrator merges in order). One spec → A → B (→ C) cycle per logical change.
