# Agent Skills

Reusable AI agent skills for Claude Code and other AI agents.

## Installation

Install any skill using [skills.sh](https://skills.sh):

```bash
npx skills add gabrieldejesusrodrigues/agent-skills
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [guided-pr-review](skills/guided-pr-review/) | Reviewer-in-the-loop PR review with the agent as navigator, not judge. Walks through intent, a map of the affected area, the shape of the diff, blast radius and history with clickable evidence, while the reviewer forms every judgment and owns the verdict. Works with a single PR, a stack of PRs (gh-stack or chained bases) or a .patch file; keeps per-area notes and a cross-repo language profile outside the repo |
| [startup-idea-validator](skills/startup-idea-validator/) | Multi-agent startup idea validation system. Searches any user-specified source (Reddit, HN, Product Hunt, web) within a user-specified time window and evaluates ideas through Product, Business, and Devil's Advocate agent perspectives |
| [tdd-lanes](skills/tdd-lanes/) | Separate test authorship from implementation to get contract-level, non-overfit tests. A spec with rule-by-rule case derivation (violating cases, boundaries, dependency failures, spec-gap detection) drives a test author with no implementation context; a different implementer makes the tests pass without weakening assertions. Stack-agnostic; lightweight and strict modes |

## License

Apache-2.0
