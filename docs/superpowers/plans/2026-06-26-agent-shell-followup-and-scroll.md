# agent-shell followup queueing + viewport auto-scroll — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make agent-shell's viewport responsive while Claude is "thinking" — the user should be able to discover how to queue a followup, and the viewport window should follow streaming output without manual scrolling.

**Architecture:** Three small additions to the user's `emacs/.emacs.d/custom.el`, all outside the upstream package source: a discoverability comment block, an `:after` advice on `agent-shell-viewport-view-last` that re-arms the auto-scroll predicate when the shell is busy, and (kept as a follow-up) an upstream issue. Each piece is independently revertible by deleting its block.

**Tech Stack:** Emacs Lisp (built-in `advice-add`/`advice-remove`, `set-window-point`, `point-max`); agent-shell internals: `agent-shell--shell-buffer`, `shell-maker--busy`, `agent-shell-viewport-view-last`.

## Global Constraints

- All changes must live in `emacs/.emacs.d/custom.el`. Do not edit files under `~/.emacs.d/straight/repos/agent-shell/`.
- Preserve the existing `use-package agent-shell` block and its options (`agent-shell-prefer-viewport-interaction t`, `agent-shell-context-sources '(region error)`, `agent-shell-preferred-agent-config (agent-shell-anthropic-make-claude-code-config)`, etc.). New code appends; it does not replace.
- The auto-scroll advice MUST NOT change point when the shell is **not** busy. Idle/historical viewing must retain upstream `(goto-char (point-min))` behavior.
- Every new symbol introduced in custom.el is prefixed `my/` to match the existing convention (see `my/agent-shell-send-symbol-at-point` at custom.el:546).
- Commits are scoped to one task each.

---

### Task 1: Add discoverability comment block

**Files:**
- Modify: `emacs/.emacs.d/custom.el` — insert immediately after line 577 (`(global-set-key (kbd "C-c t a") #'toggle-agent-shell)`) and before line 579 (the `display-buffer-alist` block).

**Interfaces:**
- Consumes: nothing.
- Produces: nothing (documentation only).

- [ ] **Step 1: Insert the comment block**

Open `emacs/.emacs.d/custom.el`. After the line `(global-set-key (kbd "C-c t a") #'toggle-agent-shell)  ; New keybinding for agent-shell` (line 577 as of this plan), insert exactly this block, preserving the blank line that already follows it:

```elisp
;; agent-shell viewport cheat-sheet (no behavior, just a navigation aid).
;;
;; When `agent-shell-prefer-viewport-interaction' is t, the viewport
;; buffer (`*Agent-… [viewport]*') has two major modes:
;;
;;   - `agent-shell-viewport-view-mode' — read-only, shows the streaming
;;     response. This is what's active while Claude is "thinking".
;;   - `agent-shell-viewport-edit-mode' — typeable compose buffer.
;;
;; From view-mode, reach edit-mode (and queue a followup if the shell is
;; busy) via:
;;
;;   r        compose a free-form followup
;;   R        compose a followup with the response block-quoted
;;   1–9      send the digit as a reply (only when idle)
;;   y, m,    send "yes", "more", "again", "continue"
;;   a, c
;;
;; Or skip view-mode entirely: `C-c a p' (agent-shell-prompt-compose)
;; opens a dedicated compose buffer immediately, even while the shell is
;; busy. Submission queues automatically.
```

- [ ] **Step 2: Byte-check the file loads cleanly**

Run: `emacs --batch -Q --eval "(progn (find-file \"/Users/eli.gladman/.dotfiles/emacs/.emacs.d/custom.el\") (check-parens))"`

Expected: exit code 0, no "Unmatched bracket" / "End of file during parsing" output.

- [ ] **Step 3: Commit**

```bash
git add emacs/.emacs.d/custom.el
git commit -m "emacs: document agent-shell viewport view/edit-mode keys

The view-mode -> edit-mode transition (r, R, digits, etc.) is the path
to queueing a followup while the agent is busy, and it's non-obvious
when first encountered.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Auto-scroll advice for streaming viewport

**Files:**
- Modify: `emacs/.emacs.d/custom.el` — insert immediately after the comment block added in Task 1, before line 579 (`(add-to-list 'display-buffer-alist …)`).

**Interfaces:**
- Consumes (from agent-shell):
  - `agent-shell-viewport-view-last` (defun in `agent-shell-viewport.el:486`) — the function we advise. Called with no arguments.
  - `agent-shell--shell-buffer` (defun in `agent-shell.el`) — returns the shell buffer associated with the current viewport, or nil.
  - `shell-maker--busy` (buffer-local variable in `shell-maker.el`) — non-nil when a turn is in flight.
- Produces:
  - `my/agent-shell-viewport-follow-tail-when-busy` — a zero-arg function attached as `:after` advice to `agent-shell-viewport-view-last`.

- [ ] **Step 1: Insert the advice**

After the comment block from Task 1 (and before the existing `;; Add agent-shell display buffer configuration` block), insert exactly:

```elisp
;; Make the viewport window follow streaming output.
;;
;; `agent-shell-viewport-view-last' ends with `(goto-char (point-min))',
;; which defeats `shell-maker--should-auto-scroll-p' (requires point at
;; point-max AND window-end at point-max). The result is that during
;; streaming, new text appends below the visible region and the window
;; never catches up.
;;
;; This advice moves point + window-point to point-max only when the
;; associated shell is busy. Historical viewing still lands at point-min
;; per upstream behavior.
(defun my/agent-shell-viewport-follow-tail-when-busy (&rest _)
  "After `agent-shell-viewport-view-last', glue point to point-max if busy."
  (when (and (derived-mode-p 'agent-shell-viewport-view-mode)
             (fboundp 'agent-shell--shell-buffer))
    (let ((shell-buffer (ignore-errors (agent-shell--shell-buffer))))
      (when (and shell-buffer
                 (buffer-live-p shell-buffer)
                 (buffer-local-value 'shell-maker--busy shell-buffer))
        (goto-char (point-max))
        (when-let* ((win (get-buffer-window (current-buffer) t)))
          (set-window-point win (point-max)))))))

(with-eval-after-load 'agent-shell
  (advice-add 'agent-shell-viewport-view-last
              :after #'my/agent-shell-viewport-follow-tail-when-busy))
```

- [ ] **Step 2: Byte-check the file loads cleanly**

Run: `emacs --batch -Q --eval "(progn (find-file \"/Users/eli.gladman/.dotfiles/emacs/.emacs.d/custom.el\") (check-parens))"`

Expected: exit code 0, no parsing errors.

- [ ] **Step 3: Reload the changed block in a running Emacs (manual verification)**

In a running Emacs that already has agent-shell loaded:
1. `M-x eval-region` over the new `defun` and `with-eval-after-load` form (or `M-x load-file` on `custom.el` if comfortable reloading the whole file).
2. Confirm `(advice-member-p 'my/agent-shell-viewport-follow-tail-when-busy 'agent-shell-viewport-view-last)` returns `t`.

Run, in `*scratch*`:

```elisp
(advice-member-p 'my/agent-shell-viewport-follow-tail-when-busy
                 'agent-shell-viewport-view-last)
```

Expected: returns a non-nil value (typically `t` or the advice symbol).

- [ ] **Step 4: Live session check — streaming follows**

1. `M-x agent-shell-anthropic-start-claude-code`.
2. From the viewport, send a long-output prompt (suggested: "explain the linux kernel CFS scheduler in detail, with as much depth as you can").
3. Observe the viewport window during streaming. The visible region must track the bottom of the response as it grows. Manual scroll is not required.

Expected: window stays glued to the tail of the streaming response.

- [ ] **Step 5: Live session check — queueing while busy**

1. While the same response from Step 4 is still streaming, press `r` in the viewport.
2. Type a short followup prompt (e.g., "now explain BFS").
3. Press `C-c C-c`.

Expected: status line / header indicator shows the request is queued (not rejected). When the current turn finishes, the queued followup starts automatically.

- [ ] **Step 6: Live session check — historical viewing is unaffected**

1. After the second turn finishes (shell is idle), press `b` in the viewport to step backward through history, then `f` to step forward.
2. Observe point placement on each page.

Expected: point lands at `point-min` of each historical interaction (upstream behavior), since `shell-maker--busy` is nil and the advice no-ops.

- [ ] **Step 7: Commit**

```bash
git add emacs/.emacs.d/custom.el
git commit -m "emacs: make agent-shell viewport follow streaming when busy

After agent-shell-viewport-view-last lands at point-min, shell-maker's
auto-scroll predicate stops firing and new tokens stream below the
visible region. This after-advice moves point and window-point to
point-max only when the associated shell is busy, restoring the
expected 'follow the tail' behavior without changing historical view.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: File the upstream issue (follow-up)

**Files:** None in this repo. External: GitHub issue at https://github.com/xenodium/agent-shell/issues/new.

**Interfaces:**
- Consumes: the behavior observations from Task 2 verification.
- Produces: an issue URL that can be referenced from custom.el in a future change if the workaround is dropped.

- [ ] **Step 1: Draft the issue body**

Title: `viewport: streaming response does not auto-scroll; followups require r/edit-mode entry`

Body (paste verbatim into the issue form):

```
With `agent-shell-prefer-viewport-interaction' set to t I hit two
papercuts while a turn is in flight:

1. Auto-scroll does not follow streaming. `agent-shell-viewport-view-last'
   ends with `(goto-char (point-min))', so as soon as a new interaction
   starts, point is no longer at `point-max'. `shell-maker--should-auto-scroll-p'
   then returns nil for every subsequent streaming insert and the window
   stays at the top while the response grows below the visible region.

2. Followups while busy require discovering `r' (or the digit/word
   replies) to leave view-mode. The mechanism is there — `agent-shell-queue-request'
   is called automatically from `compose-send-and-wait-for-response' when
   the shell is busy — but a first-time user staring at a read-only
   viewport doesn't realize that. A "compose box always available" model
   (like most chat UIs) would close the gap.

Suggested resolution: a customization variable, e.g.
`agent-shell-viewport-follow-streaming' (default nil to preserve current
behavior), that when non-nil keeps point/window-point at `point-max'
while `shell-maker--busy' is non-nil in the associated shell buffer.

For (2), maybe a hint line in the viewport header when busy
("Press r to queue a followup") would be enough without a behavior
change.

Local workaround used in the meantime:

(defun my/agent-shell-viewport-follow-tail-when-busy (&rest _)
  (when (and (derived-mode-p 'agent-shell-viewport-view-mode)
             (fboundp 'agent-shell--shell-buffer))
    (let ((shell-buffer (ignore-errors (agent-shell--shell-buffer))))
      (when (and shell-buffer
                 (buffer-live-p shell-buffer)
                 (buffer-local-value 'shell-maker--busy shell-buffer))
        (goto-char (point-max))
        (when-let* ((win (get-buffer-window (current-buffer) t)))
          (set-window-point win (point-max)))))))

(advice-add 'agent-shell-viewport-view-last
            :after #'my/agent-shell-viewport-follow-tail-when-busy)
```

- [ ] **Step 2: Submit via gh**

Run:

```bash
gh issue create \
  --repo xenodium/agent-shell \
  --title "viewport: streaming response does not auto-scroll; followups require r/edit-mode entry" \
  --body-file /tmp/agent-shell-issue.md
```

(Write the body from Step 1 to `/tmp/agent-shell-issue.md` first.)

Expected: prints the new issue URL.

- [ ] **Step 3: No commit needed**

This task produces no repo change. Copy the issue URL into the design doc's "Follow-up" section in a separate small commit if desired, but skip if not.

---

## Self-review

**Spec coverage:**
- Spec section "Typing" diagnosis → no code change required; addressed by Task 1 (discoverability).
- Spec section "Scroll" diagnosis → Task 2 (advice).
- Spec design layer 1 (discoverability comment) → Task 1.
- Spec design layer 2 (auto-scroll advice) → Task 2.
- Spec design layer 3 (optional keybinding nudge) → intentionally skipped per spec recommendation; the user already has `C-c a p`.
- Spec "Rejected alternatives" → respected (no edit-mode-as-default, no timer, no upstream patch in this change).
- Spec "Verification" steps 1–5 → mapped to Task 2 Steps 4–6.
- Spec "Follow-up" → Task 3.

**Placeholder scan:** No TBD / TODO / "add error handling" / "similar to Task N" — all code is shown verbatim, all commands are executable as written.

**Type consistency:** The advice function name `my/agent-shell-viewport-follow-tail-when-busy` is identical across the defun, the `advice-add`, the verification `advice-member-p` call, the commit message reference, and the upstream-issue snippet. No drift.

**One known imperfection:** Task 2 Step 3 uses `eval-region` / `load-file` for live reload because this is a config file, not an exported package; there is no per-function test harness in the dotfiles repo. The verification is therefore manual (Steps 4–6 in a live Emacs). This matches the spec's "Verification" section, which is also manual.
