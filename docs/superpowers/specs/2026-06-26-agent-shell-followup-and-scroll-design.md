# agent-shell: Queueing followups + viewport auto-scroll

## Problem

While Claude is generating a response in agent-shell, the viewport buffer
(`*Agent-… [viewport]*`) is unresponsive in two ways:

1. **Typing does nothing.** The buffer is in `agent-shell-viewport-view-mode`,
   which is read-only and has no self-inserting keybindings.
2. **The window does not follow the streaming response.** New text appends
   off-screen and the user has to scroll manually to catch up.

`agent-shell-prefer-viewport-interaction` is `t`, so this is the primary
interaction surface.

## Root cause (from reading agent-shell source)

### Typing
- View-mode is read-only by design (`agent-shell-viewport.el:1055-1088`).
- Followup queueing is supported via `agent-shell-queue-request`
  (`agent-shell-viewport.el:956`) and is called automatically from
  `agent-shell-viewport-compose-send-and-wait-for-response` when the shell
  is busy (`viewport.el:234`). But it only fires from **edit-mode**.
- View-mode reaches edit-mode through `r` (reply), `R` (quote-reply), or
  the canned single-character keys `1`–`9`, `y`, `m`, `a`, `c`.

The mechanism works; the entry point is non-obvious.

### Scroll
- `shell-maker--should-auto-scroll-p` (`shell-maker.el:1390`) requires
  point at `point-max` **and** window-end at `point-max`. If point is
  earlier, streaming inserts at the end without moving the window.
- `agent-shell-viewport-view-last` (`viewport.el:486`) ends with
  `(goto-char (point-min))`. After every new turn, point lands at the
  top of the new interaction, defeating the auto-scroll predicate.

## Goals

- Make followups typeable without first remembering to press `r`.
- Make the viewport window follow the streaming response by default.
- Keep changes local to the user's `custom.el`; do not patch the package.
- Stay reversible: every change can be removed by deleting a small block.

## Non-goals

- No changes to `agent-shell-mode` (the underlying shell buffer).
- No replacement of view-mode read-only semantics. View-mode is still
  read-only; we just make sure the user can reach edit-mode trivially
  and see streaming output.
- No upstream patches in this change. (See "Follow-up" below.)

## Design

Three layers in `emacs/.emacs.d/custom.el`, additive to the existing
`use-package agent-shell` block.

### 1. Discoverability comment

A short comment block listing the relevant view-mode keys (`r`, `R`,
`1`–`9`, `y`, `m`, `a`, `c`) and a reminder that `C-c a p`
(`agent-shell-prompt-compose`) opens a typeable compose buffer
immediately, even while busy. No code, just a navigation aid for the
user when reading their own config.

### 2. Auto-scroll advice

Attach an `:after` advice to `agent-shell-viewport-view-last` that, when
the associated shell is busy:

- Moves point to `(point-max)` in the viewport buffer.
- Calls `set-window-point` on the window displaying the viewport, so
  the window-end satisfies the `should-auto-scroll-p` predicate on
  subsequent streaming inserts.

When the shell is **not** busy (i.e., a historical interaction is being
viewed), leave the upstream behavior alone — going to `point-min` then
is the right call because the user is reading, not following live
output.

The advice lives in custom.el under a `defun`/`advice-add` pair named
e.g. `my/agent-shell-viewport-follow-tail-when-busy`, so removing the
behavior is a one-line `advice-remove` away.

### 3. Optional keybinding nudge

Bind a global key (suggested: `C-c a SPC`) to a small wrapper that, when
called from any agent-shell buffer, opens the prompt compose buffer
(`agent-shell-prompt-compose`) regardless of busy state. This duplicates
the existing `C-c a p` but provides an ergonomic alternative for the
"I want to queue a followup right now" reflex. Skip if `C-c a p` is
already muscle memory.

## Rejected alternatives

- **Forcing edit-mode as the default for viewport.** Would require
  hooking into more of agent-shell's lifecycle and would conflict with
  the package's intent (view-mode renders the response, edit-mode
  composes the prompt). Higher blast radius for marginal gain over (2).
- **A timer that calls `recenter` on the viewport.** Imperative, fights
  the existing `should-auto-scroll-p` mechanism, and would also fight
  the user when they intentionally scroll up.
- **Patching `should-auto-scroll-p` upstream.** Out of scope here;
  belongs in an upstream issue once the local advice has been validated.

## Verification

Manual, in a live agent-shell session:

1. Start `agent-shell-anthropic-start-claude-code`.
2. Send a prompt that produces long output (e.g., "explain the linux
   kernel scheduler in detail").
3. While streaming: confirm the viewport window scrolls with the
   response.
4. While streaming: press `r`, type a followup, press `C-c C-c`. Confirm
   the followup is queued (status line shows "Busy" / queued indicator)
   and runs after the current turn finishes.
5. After the turn completes, scroll back through history with `b`/`f`.
   Confirm the auto-scroll-on-busy advice does not interfere with
   reading old interactions (point should land at `point-min` for those,
   per upstream behavior).

## Follow-up (out of scope for this change)

File an upstream issue at xenodium/agent-shell describing:

- The viewport view-mode's read-only-by-default behavior is surprising
  for users coming from chat UIs that always-show a compose box.
- `agent-shell-viewport-view-last` calling `(goto-char (point-min))`
  defeats `shell-maker--should-auto-scroll-p` during streaming.
- Suggest a customization variable (e.g.,
  `agent-shell-viewport-follow-streaming`) defaulting nil to preserve
  current behavior.
