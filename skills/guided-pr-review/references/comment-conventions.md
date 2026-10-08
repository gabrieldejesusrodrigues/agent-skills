# Comment conventions

## Labels

Based on Conventional Comments (https://conventionalcomments.org). Format: `<label> (<decorations>): <subject>`, followed by an optional explanation.

| Label | Use for |
|---|---|
| praise | Something genuinely well done. Be specific. |
| issue | A concrete problem. Pair it with a suggestion when you can. |
| suggestion | A proposed improvement, with the reason. |
| question | Something you're unsure about. The honest default in unfamiliar code. |
| nitpick | Trivial or preference-level. Always non-blocking. |
| todo | A small, necessary change. |
| thought | An idea worth considering, not a request. |
| note | Information for the author or future readers. |
| chore | A process task before merge, such as updating a changelog. |

Decorations: `blocking`, `non-blocking`, `if-minor` (fix only if it's a small change). Google's guide uses equivalent severity prefixes: Nit, Optional (or Consider), FYI.

## Tone

- Comment on the code, not the person: "this function", not "you".
- Explain why, and point to the principle, doc or evidence behind it.
- When context is missing, ask. A question is honest, and the answer teaches the reviewer the codebase.
- Prefer clarity in the code over explanations in the thread. If the author has to explain something to the reviewer, the next reader will need it too, so suggest a rename, a comment or a simpler structure.
- Make praise specific.
- With junior authors, separate clearly what blocks the merge from what is teaching.
- Write in the reviewer's language and voice. Keep their substance; polish only for clarity.

## Examples

```
issue (blocking): `retryPayment` can charge twice if the gateway times out after
processing. `payments/service.ts:142` retries without an idempotency key. Could we
send the order ID as the key, as `refunds/service.ts:88` already does?

question (non-blocking): why move the validation from the controller into the
repository? Other repositories (`users/repo.ts`, `orders/repo.ts`) assume validated
input. Is there a case the controller didn't cover?

suggestion: this block repeats the mapping in `mappers/order.ts:30-52`. Reusing
`toOrderDto` would keep both endpoints consistent.

nitpick (non-blocking): `data2` → `pendingInvoices` would say what it holds.

praise: the migration with a backfill in batches and a feature flag is a really
safe way to roll this out.
```

## Review summary

```
**Summary:** <one or two lines on what the PR does and the overall assessment>
**Verdict:** Approve | Approve with comments | Request changes | Needs discussion
**Reviewed:** <areas and layers>
**Not reviewed:** <areas and layers, and why: out of scope, needs another reviewer, time>
**Blocking:** <n> · **Non-blocking:** <n>
```

An explicit "Not reviewed" line is part of an honest approval: it tells the author and other reviewers what still needs eyes.
