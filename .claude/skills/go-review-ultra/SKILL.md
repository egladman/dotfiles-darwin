---
name: go-review-ultra
description: Run every go-review-* skill (style, nit, skeptic, and legibility if applicable) in parallel against a target Go directory and merge the findings. Use when the user wants a full review pass — e.g. "ultra-review @pkg/foo", "run all the go reviews on internal/search", "give me everything you've got on this package". Fans out via the Agent tool, deduplicates findings, and returns one combined report. Does not write code.
---

Fan out the three go-review skills in parallel against a target directory, then merge.

## Input

The user gives you a target directory (`@pkg/foo` or a path). If the user has a **claim** to scrutinize (the go-review-nit phase 1 input), capture it too. If the directory is missing, ask. If the claim is missing, proceed without it and tell go-review-nit to skip phase 1.

## How to fan out

Spawn four `Agent` tool calls **in a single message** (parallel), using the dedicated agent types:

1. **go-review-style** (`subagent_type: go-review-style`): apply Go style and judgment conventions.
2. **go-review-nit** (`subagent_type: go-review-nit`): phase 1 (verify claim) + phase 2 (nit exported API). If no claim, tell it to skip phase 1.
3. **go-review-skeptic** (`subagent_type: go-review-skeptic`): phase 1 (bug hunt) + phase 2 (deletion sweep). No praise.
4. **pr-scope** (`subagent_type: pr-scope`): assess PR size and suggest splits if needed.

Prompt each agent with the target directory and any claim. They already have their instructions built in; just tell them what to review.

**go-review-legibility**: only run if the user supplied a list of inspected false-positive findings. This one stays as a skill (invoked via the Skill tool) because it needs user-provided input. If skipped, note it in the merged report.

## Model selection

The `Agent` tool accepts an optional `model` parameter (`sonnet` / `opus` / `haiku`) that overrides the subagent's default per call. Support both a default and a per-invocation override:

- **Default:** no `model` override. Subagents inherit the parent session's model. Keeps cost predictable.
- **Per-invocation override.** Parse a model hint from the user's prompt — e.g. "ultra-review @pkg/foo with opus", "…on sonnet", "…using haiku for the lighter passes". If a model is named, pass `model: <name>` on every fanned-out `Agent` call. If the user gives a per-lens hint ("opus for skeptic, sonnet for the rest"), honor it.
- **Recognized phrasing:** literal model name (`opus` / `sonnet` / `haiku`), optionally with `on` / `with` / `using` / `via`. Reject ambiguous hints by asking which model the user means.

## Merging the findings

Each subagent returns a list. Merge into one report:

- **Group by skill.** Keep the three sections separate — the lenses are different and collapsing them loses signal.
- **Dedupe by `file:line` within a section.** If style and nit both flag the same line for related reasons, keep both. They're different lenses. Only dedupe exact restatements.
- **Per finding, include a "why" line.** Don't just say what's wrong. Explain what goes wrong in practice if the pattern isn't fixed. The reader should learn the principle, not just the fix. Example: "Exported error variable instead of a type. Callers will compare with `==` instead of `errors.Is`, which breaks when the error is wrapped."
- **Combined severity table** at the end, drawn from all three sections. Promote any finding the subagent marked **high** to the top.
- **Top 1-3 to action first** across all skills, opinionated. Don't list ties.

If go-review-nit's phase 1 pushed back on the claim, surface that **before** the merged findings. The user needs to redirect before the rest of the report matters.

## Gotchas

- Agents don't inherit conversation context. Pass the target dir, the claim (if any), and any constraints in the spawn prompt.
- 4x the token cost of a single review. The win is parallelism and keeping intermediate searches out of the main context.

## What this skill does not do

- Write code or apply fixes. Output is a merged findings report; the user picks what to fix.
- Re-review with a fourth lens. The three sub-skills are the contract.
- Run `go-ultra-optimize` — that skill is invoke-explicitly-only and is not part of the standard review pass.
