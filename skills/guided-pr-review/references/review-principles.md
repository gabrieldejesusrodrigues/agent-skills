# Review principles

Use this file to pick the questions for each area in Phase 4 and as the checklist for the second opinion in Phase 6. Turn items into open questions tied to code locations; don't paste them as a list.

## Contents

1. Google Engineering Practices
2. The Code Review Pyramid, adapted to backend services
3. Beyond the diff
4. Operational readiness
5. Review limits and biases
6. Risk triage
7. Stacked PRs
8. Language and framework pitfalls

## 1. Google Engineering Practices

Source: https://google.github.io/eng-practices/ (Google says "CL" where we say PR).

**Standard of approval.** The goal of review is to keep the overall code health improving over time. Approve once the change clearly improves the system, even if it isn't perfect: there's no perfect code, only better code. Don't approve changes that make code health worse. To resolve disagreements, technical facts and data beat opinions and preferences; the style guide is the authority on style; design isn't pure style and should be weighed on principles; when nothing else applies, prefer consistency with the existing code.

**What to look for**, roughly in order of importance:

- Design: does the change belong here and fit the rest of the system? Is now the right time for it?
- Functionality: does it do what the author intended, and is that good for the people who use the code, end users and future developers alike? Give concurrency special attention.
- Complexity: can a reader understand it quickly? Is there over-engineering, such as generic code for needs that may never come?
- Tests: present, correct, and would they fail if the code broke?
- Naming: long enough to say what the thing is or does, short enough to read.
- Comments: explain why, not what.
- Style and consistency: follow the style guide; personal preferences are nits.
- Documentation: updated wherever behavior or usage changes.
- Every line: read every line you were asked to review. If it's too hard to understand, ask the author to clarify before going on. If you reviewed only part, say which part.
- Context: look at the whole file and the system around it. Complexity creeps in through small changes that look harmless on their own.
- Good things: say what was done well.

**Navigating a PR.** First take a broad view: does the change make sense at all? If not, say so right away. Then find the main part and review it first; if it has a major design problem, comment immediately, since the rest may change. Finally, go through the rest in a sensible order; reading tests first can help.

**Speed.** Respond within one business day at most, without breaking focused work. A quick first response matters more than a quick complete review.

**Pushback.** "I'll clean it up later" rarely happens. Ask for the cleanup now unless it's an emergency.

## 2. The Code Review Pyramid, adapted to backend services

Source: Gunnar Morling, "The Code Review Pyramid" (morling.dev, 2022). The bottom layers matter most and are the most expensive to change after merge, so that's where human attention goes. The top layers are the cheapest to fix and the best candidates for automation.

In a backend service, "API" means every surface other systems depend on: HTTP endpoints and payloads, events and messages and their schemas, the database schema, public library interfaces, configuration and CLI flags.

### API semantics (base)

- Is the surface as small as possible and as large as needed?
- Is there one way to do each thing? Is it consistent with existing APIs and conventions?
- Will it surprise consumers? Is the split between public and internal clear?
- Any breaking change? For contracts: versioning, backward and forward compatibility, and what consumers see while old and new versions coexist during deploy.
- Is it generally useful rather than tailored to a single caller?

### Implementation semantics

- Does it meet the requirements? Is it logically correct, including edge cases (empty, null, boundaries, duplicates, time zones, encodings)?
- Is there unnecessary complexity?
- Robustness: concurrency and races, error handling and propagation, timeouts, retries, idempotency, transaction boundaries.
- Performance: N+1 queries, unbounded queries or loops, missing indexes, work in hot paths.
- Security: authentication and authorization on every path, input validation, injection, secrets, personal data (LGPD) in logs, responses or events.
- Observability: can you tell in production that it works, or why it failed? Logs, metrics, traces, correlation IDs.
- New dependencies: worth it, maintained, acceptable license?

### Documentation

- Is new or changed behavior documented where people will look (README, API docs, runbooks, ADRs)?
- Is it understandable?

### Tests

- Do they pass? Is new behavior covered, including edge cases and failure paths?
- Unit tests where possible, integration tests where necessary?
- Non-functional requirements (performance, load) where relevant?
- Would the tests fail if the code broke, or do they only exercise it?

### Code style (top; automate)

- Formatting, naming conventions, duplication, readability, function length.
- If a linter or formatter could catch it, it shouldn't take human attention. Suggest automating it rather than commenting on it repeatedly.

## 3. Beyond the diff

The diff hides most of the risk. For every changed piece, check:

- Callers of changed functions and signatures, and other implementations of changed interfaces.
- Consumers of changed endpoints, events, messages and database columns, including other services and jobs.
- Missing companions: migration, configuration for every environment, feature flag, docs, client or SDK update.
- History: before accepting the removal or change of something odd, find out why it was there (Chesterton's fence).

## 4. Operational readiness

- Deploy safety: can old and new versions run side by side during rollout? Are migrations online and reversible? Does deploy order across services matter?
- Rollout and rollback: is there a flag to turn it off? What does a rollback leave behind, such as data already written in a new format?
- Configuration: are new environment variables and secrets present in every environment?
- Failure modes: what happens when a dependency is slow, down or returns something unexpected?

## 5. Review limits and biases

- Size and time: effectiveness drops beyond roughly 200 to 400 changed lines per review and after about an hour of continuous reviewing (SmartBear/Cisco study). Split the PR or the session.
- Anchoring: the first explanation you read, the author's or the AI's, shapes what you look for. Form your own hypothesis first.
- Automation bias: confident tool output feels verified. Check the evidence.
- Confirmation: once you believe the change is fine, you start skimming. In the riskiest area, look actively for evidence that you're wrong.
- Familiarity: in code you know well, you see what you expect to see. Read the actual lines.

## 6. Risk triage

Go deeper when the change touches contracts or schemas; migrations or data backfills; authentication or authorization; money, billing or quotas; personal data; concurrency, queues or retries; caching and invalidation; infra or CI configuration; shared libraries used by many services.

Go lighter on isolated internal refactors with good test coverage, docs-only changes and test-only changes, but check that changed tests still assert something meaningful.

## 7. Stacked PRs

When the PR is part of a stack, add the stack-specific questions in `stacks.md` to this pool.

## 8. Language and framework pitfalls

Every stack has failure modes that read as correct code to someone who doesn't know it well. For the languages and frameworks in the change, add questions from these categories, using what you know of that specific language or framework, tied to references:

- Async and concurrency: unawaited promises or futures, blocking calls inside async code, coroutine or goroutine lifetimes, shared mutable state.
- Absence and errors: null or undefined handling, swallowed exceptions, error values ignored, checked vs. unchecked exceptions, panics.
- Numbers and time: floating point for money, integer overflow, implicit conversions, time zones and date arithmetic.
- Resources: connections, streams, files or locks not released on every path.
- Framework behavior behind annotations or configuration: dependency injection scopes, transactions that don't apply (for example on self-invocation), ORM lazy loading and N+1, serialization defaults, validation that silently doesn't run.
- Language idioms the codebase relies on: equality semantics, mutability of defaults, copy vs. reference.

When the reviewer's level in the language is `new`, these questions matter most and benefit from a one-line explanation of the underlying behavior.
