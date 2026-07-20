---
name: ts-review-ultra
description: Use when you want a full review pass of TypeScript code. Triggers on "ultra-review src/modules/foo", "run all the ts reviews on this module", "give me everything you've got on this file". Fans out ts-review-style, ts-review-nit, and ts-review-skeptic in parallel via the Agent tool, deduplicates findings, and returns one combined report. Does not write code.
---

Fan out the three ts-review skills in parallel against a target directory, then merge.

## Input

The user gives you a target directory or file (`src/modules/foo`, a path, or a project reference). If the user has a **claim** to scrutinize (the ts-review-nit phase 1 input), capture it too. If the directory is missing, ask. If the claim is missing, proceed without it and tell ts-review-nit to skip phase 1.

## How to fan out

Spawn four `Agent` tool calls **in a single message** (parallel), using the dedicated agent types:

1. **ts-review-style** (`subagent_type: ts-review-style`): apply TypeScript style and judgment conventions.
2. **ts-review-nit** (`subagent_type: ts-review-nit`): phase 1 (verify claim) + phase 2 (nit exported API). If no claim, tell it to skip phase 1.
3. **ts-review-skeptic** (`subagent_type: ts-review-skeptic`): phase 1 (bug hunt) + phase 2 (deletion sweep). No praise.
4. **pr-scope** (`subagent_type: pr-scope`): assess PR size and suggest splits if needed.

Prompt each agent with the target directory and any claim. They already have their instructions built in; just tell them what to review.

**ts-review-legibility**: only run if the user supplied a list of inspected false-positive findings. This one stays as a skill (invoked via the Skill tool) because it needs user-provided input. If skipped, note it in the merged report.

## Model selection

The `Agent` tool accepts an optional `model` parameter (`sonnet` / `opus` / `haiku`) that overrides the subagent's default per call. Support both a default and a per-invocation override:

- **Default:** no `model` override. Subagents inherit the parent session's model. Keeps cost predictable.
- **Per-invocation override.** Parse a model hint from the user's prompt, e.g. "ts-review-ultra src/modules/foo with opus", "...on sonnet", "...using haiku". If a model is named, pass `model: <name>` on every fanned-out `Agent` call. If the user gives a per-lens hint ("opus for skeptic, sonnet for the rest"), honor it.
- **Recognized phrasing:** literal model name (`opus` / `sonnet` / `haiku`), optionally with `on` / `with` / `using` / `via`. Reject ambiguous hints by asking which model the user means.

## Merging the findings

Each subagent returns a list. Merge into one report:

- **Group by skill.** Keep the three sections separate. The lenses are different and collapsing them loses signal.
- **Dedupe by `file:line` within a section.** If style and nit both flag the same line for related reasons, keep both (they're different lenses). Only dedupe exact restatements.
- **Per finding, include a "why" line.** Don't just say what's wrong. Explain what goes wrong in practice if the pattern isn't fixed. The reader should learn the principle, not just the fix. Example: "Missing `AbortSignal` on a network call. If a Temporal activity is cancelled, this HTTP request keeps running and consuming resources until it times out on its own."
- **Combined severity table** at the end, drawn from all three sections. Promote any finding the subagent marked **high** to the top.
- **Top 1-3 to action first** across all skills, opinionated. Don't list ties.

If ts-review-nit's phase 1 pushed back on the claim, surface that **before** the merged findings. The user needs to redirect before the rest of the report matters.

## Domain-specific false positives

When the target contains Temporal workflows or activities, include this context in each subagent prompt:

> Temporal workflow files have constraints that override normal TypeScript conventions:
> - Exported Input/Output interfaces on workflows are the public contract for `client.workflow.start()` callers. Do not flag these as "only used by specs" or recommend dropping `export`.
> - Workflow functions must be standalone exported functions, not class methods. Do not flag mixed function/method styles between workflows and activities.
> - Duplicate `defineSearchAttributeKey` calls across workflow files may be required because each workflow is compiled into an isolated bundle. Verify bundle boundaries before recommending extraction.
> - `String(err)` in workflow log calls is sometimes necessary because Temporal's workflow sandbox restricts what can be serialized. Flag it but mark as needs-verification.
> - Sequential `startChild` in a loop is intentional (avoids thundering-herd). Do not flag as "should use Promise.all".

## Gotchas

- Agents don't inherit conversation context. Pass the target dir, the claim (if any), and any constraints in the spawn prompt.
- 4x the token cost of a single review. The win is parallelism and keeping intermediate searches out of the main context.

## What this skill does not do

- Write code or apply fixes. Output is a merged findings report; the user picks what to fix.
- Run `ts-review-optimize`. That skill is invoke-explicitly-only and is not part of the standard review pass.
