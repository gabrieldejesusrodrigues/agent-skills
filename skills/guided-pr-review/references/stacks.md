# Reviewing stacked PRs

A stack is an ordered chain of branches: the bottom one is based on the trunk (usually `main`) and each one above is based on the branch below. With gh-stack (https://github.com/github/gh-stack), each branch has its own PR whose base is the branch below, so each PR's diff shows only its own layer. `gh stack merge` merges every PR up to a chosen one in a single operation, so any prefix of the stack can land in the trunk on its own.

## Detecting and mapping the stack

Run `scripts/stack_map.sh <n>`. It only needs `gh` and PR metadata, so it works whether or not the stack was built with gh-stack. It prints the layers bottom to top with sizes, marks the requested PR, lists files changed in more than one layer, and notes branching (two open PRs on the same layer) or a bottom that doesn't target the trunk.

If the reviewer has gh-stack and the stack tracked locally, `gh stack view --json` gives the same order. If the gh-stack skill is installed (`gh skill install github/gh-stack`), rely on it for `gh stack` details.

## Getting the code without touching the stack

Stay read-only. Fetch every layer's head and diff remote refs, switching the detached review worktree between layers:

```bash
git fetch origin <head-1> <head-2> <head-3>
git switch --detach origin/<head-2>
scripts/pr_shape.sh origin/<head-1> origin/<head-2>
```

`gh stack checkout <n>` also works, but it creates local branches and stack metadata; use it only if the reviewer wants the `gh stack up/down` navigation. Never run `rebase`, `sync`, `push`, `submit`, `modify`, `merge` or `unstack`.

## Flow

1. **Phase 1 for the whole stack.** Read every layer's title and description. Report the overall goal and how the work was split. Checkpoint, at try-first `full` or `light`: "Before looking at the layers: how would you have split this?"
2. **Phase 3 for the whole stack.** Present the `stack_map.sh` output. Propose reviewing bottom-up: each layer's base has then already been reviewed, and the bottom layers merge first. Reading the top first to see the end state is a valid alternative for understanding, but judge layers bottom-up.
3. **Phases 2 to 5 per layer**, with that layer's base as `<base>` for `pr_shape.sh` and `familiarity.sh`. Record a verdict per layer.
4. **Stack verdict.** A short summary across layers, including what the split itself looks like.

## Questions specific to stacks

Add these to the Phase 4 question pool:

- Can this layer merge and deploy alone? Any prefix of the stack may land in the trunk, so does this layer leave the trunk building, tests passing and behavior safe without the layers above it (feature flag, dead code, an endpoint exposed but unused)?
- Does the layer have one clear purpose that can be reviewed on its own?
- Churn: code added in one layer and rewritten in a later one (`stack_map.sh` lists files changed in more than one layer). Some is normal; a lot means review effort spent on code that won't survive, or a split worth revisiting.
- Forward references: code in a lower layer that's only used by upper layers. Map where it's used (`git grep` on the top layer's head) so the reviewer can judge it with the real usage in sight.
- Contracts introduced in one layer and consumed above: review the contract in the layer that introduces it.

Comment on the layer that introduced the code, not where you happened to notice it.

## Notes and re-review

Use one review notes file per stack, `<notes dir>/reviews/stack-<bottom-pr>.md`, with a section per layer and the head SHA reviewed in each (the template has the layout). Stacks are rebased and force-pushed often; when resuming, run `git range-diff` per layer between the recorded and the current versions to separate real changes from rebase noise.
