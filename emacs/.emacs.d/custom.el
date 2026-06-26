;;; -*- lexical-binding: t -*-

(use-package emacs
  :straight t
  :init
  ;; COMMENTED OUT - This prevents ALL window splitting, including in init-window-setup
  ;; (set-frame-parameter nil 'unsplittable t)

  ;; Mouse Support in Terminal
  (unless (display-graphic-p)
    (xterm-mouse-mode 1))

  ;; Disable GUI chrome (toolbar, scrollbar, tooltips) in GUI Emacs
  (when (display-graphic-p)
    (tool-bar-mode -1)
    (scroll-bar-mode -1)
    (tooltip-mode -1))

  ;; Set default font face
  (set-face-attribute 'default nil :font "Source Code Pro")

  ;; Load theme
  (load-theme 'modus-vivendi t)

  ;; Customize window divider colors for focused/unfocused windows
  (set-face-attribute 'window-divider nil :foreground "#535353")  ; Gray for normal dividers
  (set-face-attribute 'window-divider-first-pixel nil :foreground "#535353")
  (set-face-attribute 'window-divider-last-pixel nil :foreground "#535353")

  ;; Relative line numbers - only in file buffers
  (setq-default display-line-numbers-type 'relative)
  (add-hook 'prog-mode-hook #'display-line-numbers-mode)
  (add-hook 'text-mode-hook #'display-line-numbers-mode)
  (add-hook 'conf-mode-hook #'display-line-numbers-mode)

  ;; Auto-revert buffers when files change on disk
  (global-auto-revert-mode 1)

  ;; Reduce file watching overhead for large directories
  (setq auto-revert-avoid-polling t)           ;; Use file notifications instead of polling
  (setq auto-revert-use-notify t)              ;; Enable notification system
  (setq auto-revert-interval 5)                ;; Check every 5 seconds (default is 5, increase if needed)
  (setq auto-revert-verbose nil)               ;; Don't show messages when reverting
  (setq auto-revert-remote-files nil)          ;; Don't auto-revert remote files

  ;; Reduce file notification debugging overhead
  (setq file-notify-debug nil)

  ;; UTF-8 as default encoding
  (set-charset-priority 'unicode)
  (prefer-coding-system 'utf-8-unix)

  ;; Modern editor behavior
  (delete-selection-mode 1)  ;; Type to replace selected text
  (column-number-mode 1)     ;; Show column number in mode line

  ;; Handle files with very long lines (minified code, logs, etc.)
  (global-so-long-mode 1)

  ;; Suppress GNU promotional content
  (defalias 'view-emacs-news 'ignore)
  (defalias 'describe-gnu-project 'ignore)

  ;; Maximize Emacs window by default
  (add-to-list 'default-frame-alist '(fullscreen . maximized))

  ;; Window dividers for visual separation
  (window-divider-mode 1)
  (setq window-divider-default-places t
        window-divider-default-bottom-width 3
        window-divider-default-right-width 3)

  (setq
   ;; No tabs
   indent-tabs-mode nil

   ;; Backup and save files
   make-backup-files nil
   auto-save-default nil
   backup-directory-alist `((".*" . ,(concat user-emacs-directory "backups")))
   auto-save-file-name-transforms `((".*" ,(concat user-emacs-directory "backups") t))

   ;; No lockfiles
   create-lockfiles nil

   ;; Window resizing
   window-resize-pixelwise t
   frame-resize-pixelwise t

   ;; Shell
   explicit-shell-file-name "bash"

   ;; UI improvements
   inhibit-startup-screen t                      ;; No startup screen
   initial-scratch-message nil                   ;; No scratch message
   ring-bell-function 'ignore                    ;; No bell
   use-dialog-box nil                            ;; Use minibuffer for prompts
   use-short-answers t                           ;; y/n instead of yes/no

   ;; Editing behavior
   sentence-end-double-space nil                 ;; Single space after periods
   save-interprogram-paste-before-kill t         ;; Save clipboard before killing
   mark-even-if-inactive nil                     ;; Fix undo in mark commands
   kill-whole-line t                             ;; C-k deletes whole line

   ;; Performance
   gc-cons-threshold (* 100 1024 1024)           ;; 100mb GC threshold
   read-process-output-max (* 1024 1024)         ;; 1mb - better LSP performance
   fast-but-imprecise-scrolling t                ;; Better scrolling performance

   ;; File handling
   load-prefer-newer t                           ;; Load newer elisp files
   confirm-kill-processes nil                    ;; Quit without confirmation

   ;; Display
   truncate-string-ellipsis "…"                  ;; Unicode ellipsis

   ;; TAB behavior
   tab-always-indent 'complete                   ;; Tab indents or completes
   completion-cycle-threshold 3                  ;; Cycle completions

   ;; Completion settings
   read-buffer-completion-ignore-case t          ;; Case-insensitive buffer completion
   read-file-name-completion-ignore-case t       ;; Case-insensitive file completion
   completion-ignore-case t)                     ;; Case-insensitive general completion

  :custom
  ;; Emacs 30 and newer: Disable Ispell completion function.
  (text-mode-ispell-word-completion nil))

;; Install diminish - Hide minor modes from modeline
(use-package diminish
  :straight t)

;; Sync PATH and env from the login shell. Needed for GUI Emacs on macOS,
;; harmless on Linux. Skipped in TTY where PATH is already inherited.
(use-package exec-path-from-shell
  :straight t
  :if (or (memq window-system '(mac ns x))
          (daemonp))
  :config
  (exec-path-from-shell-initialize))

;; Pop up available keybindings after any prefix key.
;; Built into Emacs 30+ — no external install needed.
(use-package which-key
  :straight (:type built-in)
  :diminish
  :custom
  (which-key-idle-delay 0.3)              ; Snappier popup (default 1.0s)
  (which-key-idle-secondary-delay 0.05)   ; Near-instant after first popup
  :config
  (which-key-mode 1))

;; Remember cursor position when reopening files.
(use-package saveplace
  :straight nil  ;; Built-in package
  :config
  (save-place-mode 1))

;; Auto-install tree-sitter grammars and remap to *-ts-mode where available.
(use-package treesit-auto
  :straight t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Install dimmer - Dim inactive buffers to highlight active one
(use-package dimmer
  :straight t
  :custom
  (dimmer-fraction 0.3)  ;; 30% dimming for inactive buffers
  :config
  (dimmer-mode))

;; Show matching parentheses
(use-package paren
  :straight nil  ;; Built-in package
  :custom
  (show-paren-style 'expression)  ;; Highlight entire expression
  :config
  (show-paren-mode 1))

;; Rainbow delimiters - Color-code nested parentheses/brackets
(use-package rainbow-delimiters
  :straight t
  :hook (prog-mode . rainbow-delimiters-mode))

;; Wrap lines in compilation buffers for better readability
(add-hook 'compilation-mode-hook 'visual-line-mode)

;; Better dired behavior - reuse buffers instead of creating new ones
(defun dired-up-directory-same-buffer ()
  "Go up to parent directory in the same buffer."
  (interactive)
  (find-alternate-file ".."))

(defun my-dired-mode-hook ()
  "Configure dired to reuse buffers instead of creating new ones."
  (put 'dired-find-alternate-file 'disabled nil)  ;; Disable the warning
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file)
  (define-key dired-mode-map (kbd "^") 'dired-up-directory-same-buffer))

(add-hook 'dired-mode-hook #'my-dired-mode-hook)

;; Fix dired warnings on macOS
(setq dired-use-ls-dired nil)

;; Project navigation - Use builtin project.el instead of Projectile
(use-package project
  :straight (:type built-in)
  :bind (("C-c k" . #'project-kill-buffers)
         ("C-c m" . #'project-compile)
         ("C-x f" . #'find-file)
         ("C-c f" . #'project-find-file)
         ("C-c F" . #'project-switch-project))
  :custom
  ;; Customize the options shown upon switching projects
  (project-switch-commands
   '((project-find-file "Find file")
     (magit-project-status "Magit" ?g)
     (deadgrep "Grep" ?h)))
  (compilation-always-kill t)
  (project-vc-merge-submodules nil))

;; Detect projects from common root files (package.json, go.mod, Gemfile, etc.).
;; Rootfile-first ordering: sub-project markers win over the monorepo git root,
;; so LSP and project commands target the actual sub-project, not the whole tree.
(use-package project-rootfile
  :straight t
  :config
  ;; Extend the default marker list with modern JS monorepo tool markers.
  ;; project.json is the Nx per-project marker (authoritative). Other entries
  ;; cover Turbo/Lerna/pnpm/Deno. tsconfig.json is intentionally excluded —
  ;; it's too noisy (appears in test dirs, build dirs, nested locations).
  (setq project-rootfile-list
        (append '("project.json"           ; Nx per-project
                  "nx.json"                 ; Nx workspace root
                  "turbo.json"              ; Turborepo
                  "lerna.json"              ; Lerna
                  "pnpm-workspace.yaml"     ; pnpm workspaces
                  "deno.json" "deno.jsonc") ; Deno
                project-rootfile-list))
  (add-to-list 'project-find-functions #'project-rootfile-try-detect))

;; Per-tab buffer/project scoping. Each tab-bar tab gets its own buffer list
;; and project context — `C-x b' and `consult-buffer' show only the current
;; tab's buffers, not the 200 across every project you've ever touched.
(use-package tabspaces
  :straight t
  :hook (after-init . tabspaces-mode)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)  ; Make C-x b scope to tab
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)                ; Kill-buffer falls back to default tab
  (tabspaces-include-buffers '("*scratch*"))     ; Scratch is visible in every tab
  (tabspaces-initialize-project-with-todo nil)   ; Don't auto-create a TODO file
  :bind-keymap ("C-c T" . tabspaces-command-map))

;; Install vertico - Modern completion UI
(use-package vertico
  :straight t
  :config
  (vertico-mode)
  (vertico-mouse-mode)
  :custom
  (vertico-count 22)
  (vertico-cycle t)
  :bind (:map vertico-map
              ("C-'"       . #'vertico-quick-exit)
              ("RET"       . #'vertico-directory-enter)
              ("C-c SPC"   . #'vertico-quick-exit)
              ("DEL"       . #'vertico-directory-delete-char)))

;; Install savehist
(use-package savehist
  :straight t
  :init
  (savehist-mode))

;; Install marginalia - Add rich annotations to completion candidates
(use-package marginalia
  :straight t
  :config
  (marginalia-mode))

(use-package eat
  :straight (:type git :host codeberg :repo "akib/emacs-eat" :files ("*.el" ("term" "term/*.el") "*.texi"
               "*.ti" ("terminfo/e" "terminfo/e/*")
               ("terminfo/65" "terminfo/65/*")
               ("integration" "integration/*")
               (:exclude ".dir-locals.el" "*-tests.el")))
  :custom
  ;; Increase latency to reduce flickering (defaults: 0.008 and 0.033)
  (eat-minimum-latency 0.05)   ; 50ms - reduces flicker at cost of slight delay
  (eat-maximum-latency 0.1))   ; 100ms - batches updates together

;; Custom toggle function for eat terminal
(defun toggle-eat-terminal ()
  "Toggle the visibility of the eat terminal window."
  (interactive)
  (let* ((eat-buffers (seq-filter (lambda (buf)
                                    (with-current-buffer buf
                                      (derived-mode-p 'eat-mode)))
                                  (buffer-list)))
         (eat-window (when eat-buffers
                       (get-buffer-window (car eat-buffers)))))
    (if eat-window
        ;; If terminal window is visible, hide it
        (delete-window eat-window)
      ;; If terminal window is not visible, show it
      (if eat-buffers
          ;; Reuse existing eat buffer
          (display-buffer (car eat-buffers))
        ;; Create new eat terminal
        (eat)))))

(global-set-key (kbd "C-c t e") #'toggle-eat-terminal)

;; Custom display action for eat terminals
(defun display-eat-terminal-right (buffer alist)
  "Display BUFFER in the Terminals container to the right of existing terminals.
If no eat terminal window exists, find the middle section of the frame."
  (let* ((terminal-window
          ;; Find a window in the Terminals container
          (cl-find-if (lambda (win)
                        (string= "Terminals" (window-parameter win 'container-name)))
                      (window-list))))
    (message "Found Terminals container window: %s" terminal-window)
    (if terminal-window
        ;; Split existing terminal window to the right
        (progn
          (message "Splitting existing terminal window to the right")
          (let ((new-window (split-window terminal-window nil 'right)))
            (set-window-buffer new-window buffer)
            (set-window-container new-window "Terminals" 'horizontal)
            (apply-container-header new-window)
            new-window))
      ;; No terminal window found, find middle section (between top and bottom)
      (message "No existing terminal window found, looking for middle section")
      (let* ((frame-h (frame-height))
             (middle-window
              (cl-find-if
               (lambda (win)
                 (and (not (window-parameter win 'window-side))  ; Not a side window
                      (let ((edges (window-edges win)))
                        (and (> (nth 1 edges) (/ frame-h 4))        ; Below top quarter
                             (< (nth 3 edges) (/ (* frame-h 3) 4)))))) ; Above bottom quarter
               (window-list)))
             (window (or middle-window (selected-window))))
        (if middle-window
            (message "Found middle window: %s" middle-window)
          (message "No middle window found, using selected window: %s" (selected-window)))
        (set-window-buffer window buffer)
        (set-window-container window "Terminals" 'horizontal)
        (apply-container-header window)
        window))))

;; Container management (i3-style with visual indicators)
(defun set-window-container (window container-name split-type)
  "Mark WINDOW as belonging to CONTAINER-NAME with SPLIT-TYPE (horizontal/vertical)."
  (set-window-parameter window 'container-name container-name)
  (set-window-parameter window 'container-split split-type))

(defun get-container-header (container-name split-type)
  "Generate header line for container with visual split indicator."
  (let* ((bg-color (pcase split-type
                     ('horizontal "#00d3d0")  ; Cyan (modus-vivendi cyan)
                     ('vertical "#b6a0ff")    ; Magenta (modus-vivendi magenta-alt-other)
                     (_ "#535353")))          ; Gray (modus-vivendi bg-active)
         (split-indicator (pcase split-type
                            ('horizontal "◧")    ; Box with left half shaded (vertical split)
                            ('vertical "⬒")      ; Box with top half shaded (horizontal split)
                            (_ "")))
         (colored-icon (propertize (format " %s " split-indicator)
                                   'face `(:background ,bg-color :foreground "#ffffff" :weight bold)))
         (container-text (propertize (format " %s " container-name)
                                     'face '(:foreground "#888888"))))
    (concat colored-icon container-text)))

(defun apply-container-header (window)
  "Apply container header to WINDOW; in code buffers (where `breadcrumb-local-mode'
is active) replace the container label with the live breadcrumb chain. Non-code
container windows (terminals, agent shells, etc.) keep the container label since
they have no breadcrumb data to substitute."
  (when-let* ((container-name (window-parameter window 'container-name))
              (split-type (window-parameter window 'container-split))
              (container-label (get-container-header container-name split-type)))
    (with-current-buffer (window-buffer window)
      (setq-local header-line-format
                  `(:eval
                    (if (bound-and-true-p breadcrumb-local-mode)
                        (concat (breadcrumb-project-crumbs)
                                " > "
                                (breadcrumb-imenu-crumbs))
                      ,container-label))))))

;; Placeholder buffer for the files container
(defun get-or-create-files-container-placeholder ()
  "Get or create the placeholder buffer for the files container."
  (or (get-buffer "*Files*")
      (with-current-buffer (get-buffer-create "*Files*")
        (insert "Files Container [H]\n\n")
        (insert "This is a placeholder. Open files with C-x C-f or project commands.\n")
        (setq buffer-read-only t)
        (current-buffer))))

;; Custom display action for files in the top container
(defun display-in-top-container (buffer alist)
  "Display BUFFER in the Files container by splitting to the right.
Finds any regular window in the top half of the frame and splits it.
Creates a placeholder window if no files container exists."
  (let* ((top-window
          ;; Find any window in the top half that's not a side window
          (cl-find-if
           (lambda (win)
             (and (not (window-parameter win 'window-side))  ; Not a side window like treemacs
                  ;; Window is in the top half of the frame
                  (< (nth 1 (window-edges win))
                     (/ (frame-height) 2))))
           (window-list))))
    (if top-window
        ;; Split the top window to the right
        (let ((new-window (split-window top-window nil 'right)))
          (set-window-buffer new-window buffer)
          (set-window-container new-window "Files" 'horizontal)
          (apply-container-header new-window)
          new-window)
      ;; No files container found - create placeholder and try again
      (let* ((placeholder (get-or-create-files-container-placeholder))
             (new-window (split-window (selected-window) nil 'above)))
        (set-window-buffer new-window placeholder)
        (set-window-container new-window "Files" 'horizontal)
        (apply-container-header new-window)
        ;; Now display the actual buffer to the right of the placeholder
        (let ((final-window (split-window new-window nil 'right)))
          (set-window-buffer final-window buffer)
          (set-window-container final-window "Files" 'horizontal)
          (apply-container-header final-window)
          final-window)))))

;; Function to create a new terminal
(defun new-eat-terminal ()
  "Create a new eat terminal window in the Terminals container."
  (interactive)
  (let ((current-prefix-arg '(4)))  ; Always force new session
    (call-interactively #'eat)))

(global-set-key (kbd "C-c t n") #'new-eat-terminal)
(global-set-key (kbd "C-c t +") #'new-eat-terminal)  ; Easier alternative keybinding

;; agent-shell dependencies and configuration.
;; Install shell-maker - required by agent-shell (from MELPA)
(use-package shell-maker
  :straight (:host github :repo "xenodium/shell-maker" :files ("*.el")))

;; Install acp.el - Agent Client Protocol support (from xenodium's repo)
(use-package acp
  :straight (:host github :repo "xenodium/acp.el" :files ("*.el")))

;; Install agent-shell for multi-LLM support via ACP
(use-package agent-shell
  :straight (:host github :repo "xenodium/agent-shell" :files ("*.el"))
  :after (shell-maker acp transient)  ;; Add transient as dependency
  :demand t
  :bind (("C-c a s" . agent-shell)                              ; Start or reuse session
         ("C-c a a" . agent-shell-toggle)                       ; Show/hide shell buffer
         ("C-c a c" . agent-shell-anthropic-start-claude-code)  ; Force Claude session
         ("C-c a q" . agent-shell-quick-insert)                 ; Quick query/insert
         ("C-c a r" . agent-shell-send-dwim)                    ; Send region or error at point
         ("C-c a p" . agent-shell-prompt-compose)               ; Multi-line prompt composer
         ("C-c a i" . agent-shell-send-screenshot)              ; Send screenshot
         ("C-c a f" . agent-shell-send-current-file)            ; Send current file
         ("C-c a w" . agent-shell-new-worktree-shell)           ; New git worktree + agent
         ("C-c a m" . agent-shell-swap-agent)                   ; Swap between agents
         ("C-c a o" . agent-shell-insert-shell-command-output)  ; Run shell cmd, insert output
         ("C-c a S" . my/agent-shell-send-symbol-at-point)      ; Send symbol's line + file:line ref
         ("C-c a P" . agent-shell-jump-to-latest-permission-button-row) ; Jump to Claude's question buttons
         ("C-c a t" . agent-shell-help-menu))                   ; Transient menu (all agent-shell cmds)
  :hook (agent-shell-mode . agent-shell-completion-mode)        ; @file mentions, /slash commands
  :custom
  (agent-shell-show-usage-at-turn-end t)                        ; Show token usage per turn
  (agent-shell-show-context-usage-indicator t)                  ; Show context budget indicator
  ;; Route all input through the compose (viewport) buffer rather than the
  ;; shell buffer's prompt area. The compose buffer is always typeable —
  ;; you can write a follow-up while Claude is still responding and it'll
  ;; queue for submission when the current turn finishes.
  (agent-shell-prefer-viewport-interaction t)
  ;; Narrow automatic context to only what the user has explicitly selected:
  ;; the active region, or the error at point. Drops the default `files' and
  ;; `line' sources so `M-x agent-shell' never silently grabs surrounding
  ;; buffer state — the agent only sees what you intentionally hand it.
  (agent-shell-context-sources '(region error))
  :config
  ;; Ensure Emacs can find npm global binaries
  (add-to-list 'exec-path (expand-file-name "~/.npm-global/bin"))

  ;; Default to Claude when starting a fresh agent-shell session
  (setq agent-shell-preferred-agent-config
        (agent-shell-anthropic-make-claude-code-config))

  ;; XDG-aligned storage for transcripts and worktrees.
  ;; Per XDG Base Directory Spec: user-specific data files belong in
  ;; $XDG_DATA_HOME (default ~/.local/share). Worktrees aren't cache —
  ;; they contain work-in-progress code — so ~/.cache would be wrong.
  ;;
  ;; Namespacing: use the VC (git) root, not project-rootfile's sub-project
  ;; boundary. This keeps all of a monorepo's sessions together (api + web
  ;; sub-projects share their monorepo's bucket) and avoids basename
  ;; collisions between same-named sub-projects across different repos.
  ;; Worktrees naturally get their own bucket (each is its own VC root).
  (setq agent-shell-dot-subdir-function
        (lambda (subdir)
          (let* ((root (or (vc-root-dir) default-directory))
                 (name (file-name-nondirectory (directory-file-name root)))
                 (xdg-data (or (getenv "XDG_DATA_HOME")
                               (expand-file-name "~/.local/share"))))
            (expand-file-name subdir
                              (expand-file-name name
                                                (expand-file-name "agent-shell"
                                                                  xdg-data))))))

  ;; Configure authentication for Claude using SSO login (not API key)
  (setq agent-shell-anthropic-authentication
        (agent-shell-anthropic-make-authentication
         :login t))  ; Use SSO login instead of API key

  ;; Set environment variables for Claude
  (setq agent-shell-anthropic-claude-environment
        (agent-shell-make-environment-variables
         :inherit-env t))  ; Inherit environment from Emacs
  ;; Optional: Configure other agents if you have their API keys
  ;; (setq agent-shell-google-authentication
  ;;       (agent-shell-google-make-authentication
  ;;        :api-key (lambda () (getenv "GOOGLE_API_KEY"))))

  ;; Set a custom system prompt if desired
  (setq agent-shell-system-prompt
        "You are a helpful AI assistant integrated with Emacs. Help with coding, writing, and general tasks."))

;; Send the line containing the symbol at point to the active agent-shell.
;; `agent-shell-send-region' attaches a clickable file:line reference, so the
;; agent sees the symbol name in code context with a jump-back link.
(defun my/agent-shell-send-symbol-at-point ()
  "Send the current line to agent-shell, anchored on the symbol at point."
  (interactive)
  (unless (thing-at-point 'symbol t)
    (user-error "No symbol at point"))
  (save-excursion
    (let ((line-bounds (bounds-of-thing-at-point 'line)))
      (goto-char (car line-bounds))
      (push-mark (cdr line-bounds) t t)
      (agent-shell-send-region))))

;; Custom toggle function for agent-shell (similar to old claude-code toggle)
(defun toggle-agent-shell ()
  "Toggle the visibility of the agent-shell window."
  (interactive)
  (let* ((agent-buffers (seq-filter (lambda (buf)
                                      (string-match-p "\\*Agent-"
                                                     (buffer-name buf)))
                                    (buffer-list)))
         (agent-window (when agent-buffers
                         (get-buffer-window (car agent-buffers)))))
    (if agent-window
        ;; If agent window is visible, hide it
        (delete-window agent-window)
      ;; If agent window is not visible, show it or create new
      (if agent-buffers
          ;; Reuse existing agent buffer
          (display-buffer (car agent-buffers))
        ;; Create new agent session with Claude
        (agent-shell-anthropic-start-claude-code)))))

(global-set-key (kbd "C-c t a") #'toggle-agent-shell)  ; New keybinding for agent-shell

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

;; Add agent-shell display buffer configuration
(add-to-list 'display-buffer-alist
             '("\\*Agent-"
               (display-buffer-reuse-window display-buffer-at-bottom)
               (window-height . 0.33)
               (reusable-frames . visible)))

;; Install Dashboard
;;(use-package dashboard
;;  :straight t
;
;;  :config
;;  (dashboard-setup-startup-hook))

;; Install golden-ratio
(use-package golden-ratio
  :straight t
  :bind (("C-c w" . golden-ratio-mode))  ;; Toggle golden-ratio on/off
  :custom
  ;; Exclude certain modes from golden-ratio
  (golden-ratio-exclude-modes '(ediff-mode
                                 dired-mode
                                 magit-mode
                                 treemacs-mode
                                 help-mode
                                 compilation-mode))
  ;; Exclude buffers by name pattern (diff buffers, etc.)
  (golden-ratio-exclude-buffer-regexp '("^\\*ediff"
                                         "^\\*diff"
                                         "^\\*Diff"))
  :init
  (golden-ratio-mode 1))

;; Install hydra for repeatable commands
(use-package hydra
  :straight t)

;; Tame popup buffers (help, compilation, warnings, etc.) — one keybind to
;; toggle/cycle, one to (de)mark a buffer as a popup. Deliberately excludes
;; *eat* and *Agent-* buffers: those have bespoke toggle functions and custom
;; display-buffer-alist entries in this config.
(use-package popper
  :straight t
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*"
     "\\*Warnings\\*"
     "\\*Backtrace\\*"
     "\\*Async Shell Command\\*"
     "\\*Flycheck errors\\*"
     "\\*Embark Collect"
     "\\*eldoc\\*"
     "Output\\*$"
     help-mode
     helpful-mode
     compilation-mode
     flymake-diagnostics-buffer-mode
     occur-mode
     xref--xref-buffer-mode
     vundo-mode
     magit-process-mode))
  ;; Match the ~33% heights used elsewhere in display-buffer-alist; default
  ;; 0.4 felt invasive next to the container layout.
  (popper-window-height 0.33)
  ;; Per-project popup tracking — M-` cycles through THIS project's popups,
  ;; not every popup across every project. Uses project.el.
  (popper-group-function #'popper-group-by-project)
  ;; Skip M-0 so it stays bound to `treemacs-select-window'. M-1..M-9 still
  ;; dispatch to popups 1-9 from the echo area.
  (popper-echo-dispatch-keys '("M-1" "M-2" "M-3" "M-4" "M-5"
                                "M-6" "M-7" "M-8" "M-9"))
  :init
  (popper-mode 1)
  (popper-echo-mode 1))

;; Better window resizing with hydra (i3-style)
(defhydra hydra-window-resize (:color red :hint nil)
  "
Window Resize Mode (any other key to exit)
_<left>_: shrink horizontally  _<right>_: enlarge horizontally
_<down>_: shrink vertically    _<up>_: enlarge vertically
"
  ("<left>" (if golden-ratio-mode
                (message "Golden ratio is enabled! Disable it with C-c w first")
              (shrink-window-horizontally 5)))
  ("<right>" (if golden-ratio-mode
                 (message "Golden ratio is enabled! Disable it with C-c w first")
               (enlarge-window-horizontally 5)))
  ("<down>" (if golden-ratio-mode
                (message "Golden ratio is enabled! Disable it with C-c w first")
              (shrink-window 5)))
  ("<up>" (if golden-ratio-mode
              (message "Golden ratio is enabled! Disable it with C-c w first")
            (enlarge-window 5)))
  ("q" nil "quit"))

(global-set-key (kbd "C-c r") 'hydra-window-resize/body)

;; i3-style window navigation with hydra
(defhydra hydra-window-nav (:color red :hint nil)
  "
Window Navigation Mode (any other key to exit)
_h_/_<left>_: left    _l_/_<right>_: right
_j_/_<down>_: down    _k_/_<up>_: up
"
  ("h" windmove-left)
  ("<left>" windmove-left)
  ("l" windmove-right)
  ("<right>" windmove-right)
  ("j" windmove-down)
  ("<down>" windmove-down)
  ("k" windmove-up)
  ("<up>" windmove-up)
  ("q" nil "quit"))

(global-set-key (kbd "C-c n") 'hydra-window-nav/body)

;; Fullscreen/Monocle mode (i3-style)
(defvar monocle-mode-previous-configuration nil
  "Store the window configuration before entering monocle mode.")

(defvar monocle-mode-active nil
  "Track whether monocle mode is currently active in this frame.")

(defun update-monocle-indicator ()
  "Update visual indicator for monocle mode with fullscreen icon."
  (if monocle-mode-active
      ;; Fullscreen icon with red background, matching split indicator style
      (setq-local header-line-format
                  (concat
                   (propertize " ⬚ " 'face '(:background "#ff8059" :foreground "#ffffff" :weight bold))
                   (propertize " Fullscreen " 'face '(:foreground "#888888"))))
    (setq-local header-line-format nil)))

(defun toggle-monocle-mode ()
  "Toggle fullscreen/monocle mode for the current window (i3-style).
Saves the window configuration and restores it when toggling off."
  (interactive)
  (if monocle-mode-active
      ;; Restore previous configuration
      (progn
        (when monocle-mode-previous-configuration
          (set-window-configuration monocle-mode-previous-configuration)
          (setq monocle-mode-previous-configuration nil))
        (setq monocle-mode-active nil)
        ;; Remove header from all windows
        (walk-windows (lambda (win)
                        (with-current-buffer (window-buffer win)
                          (setq-local header-line-format nil)))
                      nil t)
        (message "Fullscreen disabled"))
    ;; Enter monocle mode
    (setq monocle-mode-previous-configuration (current-window-configuration))
    (delete-other-windows)
    (setq monocle-mode-active t)
    ;; Add subtle visual indicator
    (update-monocle-indicator)
    (message "Fullscreen enabled")))

(global-set-key (kbd "C-c C-f") #'toggle-monocle-mode)

;; Install consult - Enhanced completion commands
(use-package consult
  :straight t
  :config
  (defun pt/yank-pop ()
    "As yank, but calling consult-yank-pop."
    (interactive)
    (let ((point-before (point)))
      (consult-yank-pop)
      (indent-region point-before (point))))

  :bind (("C-c i"   . #'consult-imenu)
         ("C-c b"   . #'consult-buffer)
         ("C-x b"   . #'consult-buffer)
         ("C-c e"   . #'consult-recent-file)
         ("C-c y"   . #'pt/yank-pop)
         ("C-c R"   . #'consult-bookmark)
         ("C-c `"   . #'consult-flycheck)
         ("C-c h"   . #'consult-ripgrep)
         ("C-c j"   . #'consult-line)
         ("C-h a"   . #'consult-apropos))
  :custom
  (completion-in-region-function #'consult-completion-in-region)
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  (consult-project-root-function #'deadgrep--project-root))  ;; ensure ripgrep works

;; deadgrep - Project-wide search using ripgrep
(use-package deadgrep
  :straight t
  :bind (("C-c H" . #'deadgrep)))

;; Bridge consult's completing-read UI to flycheck's error list. Bound to
;; `C-c `' over in the consult block; this package is what makes it work.
(use-package consult-flycheck
  :straight t
  :after (consult flycheck))

;; visual-regexp - Better find-and-replace UI with visual feedback
(use-package visual-regexp
  :straight t
  :bind (("C-c 5" . #'vr/replace)))

;; Modern in-buffer completion popup. Corfu + corfu-terminal is the upstream-
;; recommended setup (corfu uses child frames in GUI, corfu-terminal swaps in
;; popon overlays for TTY). All corfu settings live here; corfu-terminal below
;; just toggles TTY support.
(use-package corfu
  :straight t
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                          ; Auto-trigger completion
  (corfu-auto-prefix 0)                   ; Start completing at first char
  (corfu-auto-delay 0)                    ; No delay before showing candidates
  (corfu-cycle t)                         ; Wrap around candidates
  (corfu-preselect 'directory)            ; Select first candidate (except dirs)
  (corfu-preview-current 'insert)         ; Preview current candidate inline
  (corfu-preselect-first nil)
  (corfu-on-exact-match nil)              ; Don't auto-expand on exact match
  (corfu-quit-no-match t)
  (corfu-popupinfo-delay '(0.5 . 0.2))    ; Docs popup: 0.5s initial, 0.2s subsequent
  ;; Skip agent-shell buffers — agent-shell-completion-mode already provides
  ;; @file mentions and /slash commands; corfu's auto-completion on top of
  ;; that conflicts (causes "Corfu detected an error" on every keystroke).
  (corfu-excluded-modes '(agent-shell-mode))
  :bind (:map corfu-map
              ("M-SPC"      . corfu-insert-separator)
              ("S-<return>" . corfu-insert)
              ("RET"        . nil))       ; Free RET; re-bound in shells below
  :config
  ;; Doc popup alongside completions (signatures, docstrings).
  (corfu-popupinfo-mode 1)
  ;; Re-enable RET only in shells where you actually want to send/accept.
  (keymap-set corfu-map "RET"
              `(menu-item "" nil :filter
                          ,(lambda (&optional _)
                             (and (derived-mode-p 'eshell-mode 'comint-mode)
                                  #'corfu-send))))
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-quit-at-boundary t
                          corfu-quit-no-match t
                          corfu-auto nil)
              (corfu-mode))))

;; TTY support for corfu. Only enabled when running without a graphical frame.
(use-package corfu-terminal
  :straight t
  :after corfu
  :unless (display-graphic-p)
  :config
  (corfu-terminal-mode +1))

;; Install lsp-mode
;; https://github.com/minad/corfu/wiki#configuring-corfu-for-lsp-mode

(use-package orderless
  :straight t
  :custom
  (completion-styles '(orderless)))

;; ctrlf - Better buffer search (like C-f in browsers)
(use-package ctrlf
  :straight t
  :config
  (ctrlf-mode))

;; Completion filtering = orderless (above). No prescient sorting layer —
;; kept the pipeline shallow on purpose.

;; dumb-jump - Jump to definition without LSP
(use-package dumb-jump
  :straight t
  :bind (("C-c J" . #'dumb-jump-go)))

;; Project + imenu breadcrumbs in the header line. Enabled globally.
;; NOTE: breadcrumb writes to `header-line-format', so it overrides the
;; container/focus-indicator headers in non-prog buffers too. If that gets
;; annoying, change back to `:hook (prog-mode . breadcrumb-local-mode)'.
(use-package breadcrumb
  :straight t
  :init
  (breadcrumb-mode))

;; embark-consult - Integration between embark and consult (separate MELPA package)
(use-package embark-consult
  :straight t)

;; embark - Contextual actions on completion candidates.
;; Also wires `prefix-help-command' so pressing C-h after any prefix gives a
;; searchable completing-read of every binding under it. Pairs with which-key:
;; which-key handles passive/ambient discovery (auto-popup), embark handles
;; active/searchable discovery (C-h on demand). C-h B browses ALL bindings.
(use-package embark
  :straight t
  :demand t
  :bind (("C-c E" . #'embark-act)
         ("C-h B" . #'embark-bindings))
  :custom
  (prefix-help-command #'embark-prefix-help-command)
  :config
  (require 'embark-consult)
  (add-hook 'embark-collect-mode-hook 'consult-preview-at-point-mode))

;; Autocomplete - Use builtin completion-at-point instead of company
(global-set-key (kbd "C-.") #'completion-at-point)

(use-package lsp-mode
  :straight t
  :custom
  (lsp-completion-provider :none) ;; we use Corfu!
  (lsp-auto-guess-root t)         ;; Use project.el to find workspace root, no prompt
  :init
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(flex))) ;; Configure flex
  :hook
  (lsp-completion-mode . my/lsp-mode-setup-completion))

(use-package lsp-ui
  :straight t
  :hook (lsp-mode . lsp-ui-mode))


;; Install cape
(use-package cape
  :straight t
  :init
  ;;(add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-tex)
  ;;(add-to-list 'completion-at-point-functions #'cape-abbrev)
  ;;(add-to-list 'completion-at-point-functions #'cape-ispell)
  ;;(add-to-list 'completion-at-point-functions #'cape-dict)
  ;;(add-to-list 'completion-at-point-functions #'cape-symbol)
  (add-to-list 'completion-at-point-functions #'cape-line))

(use-package transient
  :straight t
  :demand t  ;; Force immediate loading
  :custom
  ;; Cursor + arrow-key navigation inside transient popups. Without this,
  ;; transients are keypress-only with no visible selection indicator.
  (transient-enable-popup-navigation t)
  ;; Show ALL suffixes regardless of level (default 4 hides "advanced"
  ;; options). Stops the "where is the X option in this menu?" problem.
  (transient-default-level 7)
  ;; Drop the mode-line from inside the popup — it's a menu, not a buffer.
  (transient-mode-line-format nil)
  ;; Highlight suffixes whose internal binding has been remapped globally,
  ;; so you can tell when an override is shadowing the menu key.
  (transient-highlight-mismatched-keys t)
  ;; Footer with the universal keys (quit, undo, cycle level, set/save).
  ;; Discoverability win for unfamiliar transients; reassess after ~2 weeks.
  (transient-show-common-commands t)
  ;; Shorter delay before the popup appears (default 1s feels sluggish).
  (transient-show-popup 0.2)
  :config
  ;; Make <escape> close the transient (default exit is C-g, which fights
  ;; every modern UI convention). Also stops "Unbound suffix" on Escape.
  (keymap-set transient-base-map "<escape>" #'transient-quit-one))

;; Casual Suite — transient menus for built-in Emacs modes. "Recognition over
;; recall": press the entry-point key (usually C-o in the relevant mode), then
;; single letters in the popup. Your existing keybindings still work; casual
;; is purely additive.
;;
;; NOTE: Global C-o shadows `open-line' (the menu still exposes it). The
;; canonical install also binds M-g globally to `casual-avy-tmenu', omitted
;; here because M-g is Emacs' goto prefix (goto-line, next-error, etc).
(use-package casual-suite
  :straight t
  :after transient
  :bind (("C-o" . casual-editkit-main-tmenu))
  :config
  (keymap-set calc-mode-map           "C-o" #'casual-calc-tmenu)
  (keymap-set dired-mode-map          "C-o" #'casual-dired-tmenu)
  (keymap-set isearch-mode-map        "C-o" #'casual-isearch-tmenu)
  (keymap-set ibuffer-mode-map        "C-o" #'casual-ibuffer-tmenu)
  (keymap-set ibuffer-mode-map        "F"   #'casual-ibuffer-filter-tmenu)
  (keymap-set ibuffer-mode-map        "s"   #'casual-ibuffer-sortby-tmenu)
  (keymap-set Info-mode-map           "C-o" #'casual-info-tmenu)
  (keymap-set reb-mode-map            "C-o" #'casual-re-builder-tmenu)
  (keymap-set reb-lisp-mode-map       "C-o" #'casual-re-builder-tmenu)
  (keymap-set bookmark-bmenu-mode-map "C-o" #'casual-bookmarks-tmenu)
  (with-eval-after-load 'org-agenda
    (keymap-set org-agenda-mode-map   "C-o" #'casual-agenda-tmenu))
  (with-eval-after-load 'symbol-overlay
    (keymap-set symbol-overlay-map    "C-o" #'casual-symbol-overlay-tmenu)))

;; Install diff-hl - Indication of local VCS changes
(use-package diff-hl
  :straight t)

;; Install wind-move - Window navigation with M-<arrow>
(use-package windmove
  :straight t)

;; Use M-<arrow> instead of C-<arrow> to avoid conflicts with macOS Rectangle app
(windmove-default-keybindings 'meta)

;; Jump to any visible character with 2-3 keystrokes. Replaces "scroll +
;; search + click" navigation for in-buffer motion. Already installed
;; transitively by casual-avy; this block makes the dependency explicit
;; and binds `avy-goto-char-timer' as the daily-driver entry point.
(use-package avy
  :straight t
  :bind (("M-j" . avy-goto-char-timer))
  :custom
  (avy-timeout-seconds 0.3))           ; Faster trigger than default 0.5

;; Letter-on-each-window picker. Better than cycling with M-<arrow> once
;; there are 3+ windows. Installed transitively via treemacs; this just
;; binds it and uses home-row letters for the hints.
(use-package ace-window
  :straight t
  :bind (("M-o" . ace-window))
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (aw-scope 'frame))                   ; Don't pick across separate frames

;; Enable `diff-hl' support by default in programming buffers
(add-hook 'prog-mode-hook #'diff-hl-mode)

;; Install expand-region
(use-package expand-region
  :straight t)
(global-set-key (kbd "M-2") 'er/expand-region)

;; Visual undo tree built on Emacs' native linear undo — no separate undo
;; history file, no data-loss bugs (unlike undo-tree).
(use-package vundo
  :straight t
  :bind (("C-c u" . vundo))
  :custom
  (vundo-glyph-alist vundo-unicode-symbols)
  :config
  ;; <escape> closes the tree (q and C-g also work — vundo's defaults).
  (keymap-set vundo-mode-map "<escape>" #'vundo-quit))

;; Install go-mode - Golang Support
(use-package go-mode
  :straight t)

;; Set up before-save hooks to format buffer and add/delete imports.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)
(add-hook 'go-ts-mode-hook #'lsp-go-install-save-hooks)

;;(use-package flycheck-golangci-lint
;;  :straight t
;;  :hook (go-mode . flycheck-golangci-lint-setup))

;; Enable lsp-mode for go buffers (both regex and tree-sitter major modes)
(add-hook 'go-mode-hook 'lsp-deferred)
(add-hook 'go-ts-mode-hook 'lsp-deferred)

;; Install yaml-mode
(use-package yaml-mode
  :straight t)

;; Install json-mode
(use-package json-mode
  :straight t)

;; Install typescript mode
(use-package typescript-mode
  :straight t
  :hook ((typescript-mode . lsp-deferred)
         (typescript-ts-mode . lsp-deferred)
         (tsx-ts-mode . lsp-deferred)))

;; Install docker-mode
(use-package dockerfile-mode
  :straight t)

;; Install protobuf-mode
(use-package protobuf-mode
  :straight t
  :defer t)

;; Install markdown-mode - Use GitHub-flavored Markdown by default
(use-package markdown-mode
  :straight t
  :bind (:map markdown-mode-map
              ("C-c C-s a" . markdown-table-align))
  :mode ("\\.md\\'" . gfm-mode))

;; Install org-modern - Beautiful rendering for org-mode
(use-package org-modern
  :straight t
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-hide-stars t
        org-modern-table nil))

;; Install flycheck - Syntax Checking
(use-package flycheck
  :straight t
  :defer 2
  :diminish
  :custom
  (flycheck-display-errors-delay .3)
  :init
  (global-flycheck-mode))


;; Install nerd-icons - Modern icons that work in terminal
(use-package nerd-icons
  :straight t)

;; Install nerd-icons-dired - Icons in dired mode
(use-package nerd-icons-dired
  :straight t
  :after nerd-icons
  :hook (dired-mode . nerd-icons-dired-mode))

;; Modern dired front-end: file previews, columns, magit-style transient
;; menus, full path breadcrumbs. Overrides plain dired everywhere so
;; existing dired bindings (and casual-dired's C-o menu) keep working.
(use-package dirvish
  :straight t
  :init
  (dirvish-override-dired-mode)
  :custom
  ;; Quick-access shortcuts inside dirvish (press `qq' or use the menu).
  (dirvish-quick-access-entries
   '(("h" "~/"           "Home")
     ("d" "~/Downloads/" "Downloads")
     ("s" "~/src/"       "Source")
     ("e" "~/.emacs.d/"  "Emacs config")
     ("f" "~/.dotfiles/" "Dotfiles")))
  ;; Columns shown in dirvish buffers. `nerd-icons' uses nerd-icons-dired
  ;; (which is already installed above); the others come from dirvish.
  (dirvish-attributes
   '(nerd-icons file-time file-size collapse subtree-state vc-state git-msg)))
  ;; NOTE: dirvish-peek-mode (file previews in the minibuffer during find-file)
  ;; is intentionally NOT enabled — it reads every candidate on cursor move,
  ;; which makes C-x f painfully slow in busy directories. Re-enable with
  ;; M-x dirvish-peek-mode if you want it for a specific session.

;; Install magit - Git client
(use-package magit
  :straight t
  :diminish magit-auto-revert-mode
  :bind (("C-c g" . #'magit-status))
  :custom
  (magit-repository-directories '(("~/src" . 1)))  ;; Scan ~/src for git repos
  :config
  (add-to-list 'magit-no-confirm 'stage-all-changes))  ;; Don't confirm staging all changes

;; Show author + commit summary inline for the line under the cursor.
(use-package blamer
  :straight t
  :custom
  (blamer-idle-time 0.3)
  (blamer-min-offset 70)
  :custom-face
  (blamer-face ((t :foreground "#7a88cf" :background unspecified :italic t)))
  :config
  (global-blamer-mode 1))

;; libgit integration for better performance (requires native compilation)
;;(use-package libgit
;;  :straight t
;;  :after magit)

;; Use libgit backend for faster operations
;;(use-package magit-libgit
;;  :straight t
;;  :after (magit libgit))

;; Forge - GitHub/GitLab integration for magit
(use-package forge
  :straight t
  :after magit)

;; Hack to eliminate forge weirdness with bug-reference-auto-setup-functions
(unless (boundp 'bug-reference-auto-setup-functions)
  (defvar bug-reference-auto-setup-functions '()))

;; Code review integration for pull requests
(use-package code-review
  :straight t
  :after magit
  :commands (code-review-forge-pr-at-point
             code-review-comment-jump-next
             code-review-comment-jump-previous)
  :bind (:map forge-topic-mode-map
              ("C-c r" . #'code-review-forge-pr-at-point))
  :bind (:map code-review-mode-map
              ("C-c n" . #'code-review-comment-jump-next)
              ("C-c p" . #'code-review-comment-jump-previous)))

;; Install treemacs
(use-package treemacs
 :straight t
 :init
 (with-eval-after-load 'winum
   (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
 ;; Set these BEFORE treemacs loads so they're active when window is created
 (setq treemacs-position 'left)
 (setq treemacs-width 35)
 (setq treemacs-display-in-side-window t)
 :hook (treemacs-mode . (lambda () (setq mode-line-format nil)))  ; Hide mode-line in treemacs
 :config
 (progn
   (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
         treemacs-deferred-git-apply-delay        0.5
         treemacs-directory-name-transformer      #'identity
         treemacs-display-in-side-window          t
         treemacs-eldoc-display                   'simple
         treemacs-file-event-delay                5000  ;; Increased delay before refreshing
         treemacs-file-extension-regex            treemacs-last-period-regex-value
         treemacs-file-follow-delay               0.2
         treemacs-file-name-transformer           #'identity
         treemacs-file-watch-delay                5000  ;; Delay before processing file watch events
         treemacs-follow-after-init               t
         treemacs-expand-after-init               t
         treemacs-find-workspace-method           'find-for-file-or-pick-first
         treemacs-git-command-pipe                ""
         treemacs-goto-tag-strategy               'refetch-index
         treemacs-header-scroll-indicators        '(nil . "^^^^^^")
         treemacs-hide-dot-git-directory          t
         treemacs-indentation                     2
         treemacs-indentation-string              " "
         treemacs-is-never-other-window           nil
         treemacs-max-git-entries                 5000
         treemacs-missing-project-action          'ask
         treemacs-move-forward-on-expand          nil
         treemacs-no-png-images                   nil
         treemacs-no-delete-other-windows         t
         treemacs-project-follow-cleanup          nil
         treemacs-persist-file                    (expand-file-name ".cache/treemacs-persist" user-emacs-directory)
         treemacs-position                        'left
         treemacs-read-string-input               'from-child-frame
         treemacs-recenter-distance               0.1
         treemacs-recenter-after-file-follow      nil
         treemacs-recenter-after-tag-follow       nil
         treemacs-recenter-after-project-jump     'always
         treemacs-recenter-after-project-expand   'on-distance
         treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask" "/.git" "/dist" "/build" "/target" "/.next" "/.cache")
         treemacs-project-follow-into-home        nil
         treemacs-show-cursor                     nil
         treemacs-show-hidden-files               t
         treemacs-silent-filewatch                nil
         treemacs-silent-refresh                  nil
         treemacs-sorting                         'alphabetic-asc
         treemacs-select-when-already-in-treemacs 'move-back
         treemacs-space-between-root-nodes        t
         treemacs-tag-follow-cleanup              t
         treemacs-tag-follow-delay                1.5
         treemacs-text-scale                      nil
         treemacs-user-mode-line-format           nil
         treemacs-user-header-line-format         nil
         treemacs-wide-toggle-width               70
         treemacs-width                           35
         treemacs-width-increment                 1
         treemacs-width-is-initially-locked       t
         treemacs-workspace-switch-cleanup        nil)

   ;; The default width and height of the icons is 22 pixels. If you are
   ;; using a Hi-DPI display, uncomment this to double the icon size.
   ;;(treemacs-resize-icons 44)

   (treemacs-follow-mode t)
   ;; Auto-swap treemacs root to the project containing the current buffer.
   ;; Without this, treemacs sits in whatever workspace was last persisted
   ;; — independent of project.el's current project.
   (treemacs-project-follow-mode t)
   (treemacs-filewatch-mode t)
   (treemacs-fringe-indicator-mode 'always)
   (when treemacs-python-executable
     (treemacs-git-commit-diff-mode t))

   (pcase (cons (not (null (executable-find "git")))
                (not (null treemacs-python-executable)))
     (`(t . t)
      (treemacs-git-mode 'deferred))
     (`(t . _)
      (treemacs-git-mode 'simple)))

   (treemacs-hide-gitignored-files-mode nil))
 :bind
 (:map global-map
       ("M-0"       . treemacs-select-window)
       ("C-x t 1"   . treemacs-delete-other-windows)
       ("C-x t t"   . treemacs)  ; Keep default
       ("C-c t t"   . treemacs)  ; Complementary to C-c t c
       ("C-x t d"   . treemacs-select-directory)
       ("C-x t B"   . treemacs-bookmark)
       ("C-x t C-t" . treemacs-find-file)
       ("C-x t M-t" . treemacs-find-tag)))

(use-package treemacs-magit
 :straight t
 :after treemacs
 :after magit)


(defvar window-snapshots '())

(defun save-window-snapshot ()
  "Save the current window configuration into `window-snapshots` alist."
  (interactive)
  (let ((key (read-string "Enter a name for the snapshot: ")))
    (setf (alist-get key window-snapshots) (current-window-configuration))
    (message "%s window snapshot saved!" key)))

(defun get-window-snapshot (key)
  "Given a KEY return the saved value in `window-snapshots` alist."
  (let ((value (assoc key window-snapshots)))
    (cdr value)))

(defun restore-window-snapshot ()
  "Restore a window snapshot from the window-snapshots alist."
  (interactive)
  (let* ((snapshot-name (completing-read "Choose snapshot: " (mapcar #'car window-snapshots)))
	 (snapshot (get-window-snapshot snapshot-name)))
    (if snapshot
	(set-window-configuration snapshot)
      (message "Snapshot %s not found" snapshot-name))))

;; Keybindings for window snapshots
(global-set-key (kbd "C-c W s") #'save-window-snapshot)
(global-set-key (kbd "C-c W r") #'restore-window-snapshot)

;; Manual fix for treemacs positioning
(defun fix-treemacs-position ()
  "Manually fix treemacs position to left side with correct width."
  (interactive)
  (when (treemacs-get-local-window)
    ;; Close treemacs
    (delete-window (treemacs-get-local-window)))
  ;; Force settings
  (setq treemacs-position 'left)
  (setq treemacs-width 35)
  (setq treemacs-display-in-side-window t)
  ;; Reopen treemacs
  (treemacs))

(global-set-key (kbd "C-c W f") #'fix-treemacs-position)


(defun pbcopy ()
  "Copy region to macOS clipboard using pbcopy."
  (interactive)
  (let ((deactivate-mark t))
    (call-process-region (point) (mark) "pbcopy")))

(defun pbpaste ()
  "Paste from macOS clipboard using pbpaste."
  (interactive)
  (call-process-region (point) (if mark-active (mark) (point)) "pbpaste" t t))

(defun pbcut ()
  "Cut region to macOS clipboard using pbcopy."
  (interactive)
  (pbcopy)
  (delete-region (region-beginning) (region-end)))

;; Keybindings for macOS clipboard functions
(global-set-key (kbd "C-c c") #'pbcopy)
(global-set-key (kbd "C-c v") #'pbpaste)
(global-set-key (kbd "C-c x") #'pbcut)

;; Auto-indent on yank/paste (like TextMate)
(defun yank-and-indent ()
  "Yank and then indent the pasted region."
  (interactive)
  (let ((point-before (point)))
    (when mark-active
      (delete-region (region-beginning) (region-end)))
    (yank)
    (indent-region point-before (point))))

;; Bind C-y to auto-indent yank, C-Y to normal yank
(global-set-key (kbd "C-y") #'yank-and-indent)
(global-set-key (kbd "C-S-y") #'yank)  ;; Fallback to normal yank

;; Copy file name to clipboard (like VS Code)
(defun copy-file-name-to-clipboard (do-not-strip-prefix)
  "Copy the current buffer file name to the clipboard.
The path will be relative to the project's root directory, if set.
Invoking with a prefix argument (C-u) copies the full path."
  (interactive "P")
  (letrec
      ((fullname (if (equal major-mode 'dired-mode) default-directory (buffer-file-name)))
       (root (project-root (project-current)))
       (relname (file-relative-name fullname root))
       (should-strip (and root (not do-not-strip-prefix)))
       (filename (if should-strip relname fullname)))
    (kill-new filename)
    (message "Copied buffer file name '%s' to the clipboard." filename)))

(global-set-key (kbd "C-c p") #'copy-file-name-to-clipboard)

;; Reload Emacs configuration
(defun reload-emacs-config ()
  "Reload the Emacs configuration file."
  (interactive)
  (load-file user-init-file)
  (message "Emacs configuration reloaded!"))

(global-set-key (kbd "C-c L") #'reload-emacs-config)

;; Use ibuffer instead of default buffer list
(global-set-key (kbd "C-x C-b") #'ibuffer)

;; Keybinding discovery is now layered across three mechanisms — no more
;; hand-maintained cheatsheet:
;;   - Casual menus: press C-o globally (or in dired/info/ibuffer/calc/isearch/
;;     bookmarks) for transient menus with single-letter actions.
;;   - which-key: press any prefix and pause briefly to see all next-keys.
;;   - embark: press C-h after a prefix for a searchable completing-read; or
;;     C-h B to browse every active binding.

;; Configure display-buffer-alist to control where buffers appear
(setq display-buffer-alist
      '(("\\*eat\\*.*"  ; Match all eat terminals: *eat*, *eat*<2>, etc.
         (display-buffer-reuse-window display-eat-terminal-right)
         (reusable-frames . visible))
        ;; Ediff buffers open in the top container
        ("\\*Ediff Control Panel\\*\\|^\\*ediff-.*"
         (display-buffer-reuse-window display-in-top-container)
         (inhibit-same-window . t))
        ;; Default: regular files (NOT starting with * or space) open in the top container
        ;; This excludes treemacs buffers which start with " *Treemacs-Buffer-"
        ("^[^ *]"
         (display-buffer-reuse-window display-in-top-container)
         (reusable-frames . visible))))

;; Default window setup on startup
(defun init-window-setup ()
  "Set up initial window configuration with treemacs, cheatsheet, and terminal.

Only runs when launching Emacs without specifying files (e.g., 'emacs -nw').
When opening specific files (e.g., 'emacs -nw file.txt'), this setup is skipped."
  (interactive)
  (when (and (not (daemonp))
             (< (length command-line-args) 2))
    (condition-case err
        (progn
          (message "Starting init-window-setup...")

          ;; Start clean
          (delete-other-windows)
          (message "Deleted other windows")

          ;; Make sure we start in scratch buffer in a regular window
          (switch-to-buffer "*scratch*")
          (message "Switched to scratch, current window: %s" (selected-window))

          ;; Open treemacs as a side window without selecting it
          (when (fboundp 'treemacs)
            (let ((original-window (selected-window)))
              ;; Open treemacs - it will create a side window
              (treemacs)
              ;; Force selection back to original window
              (when (window-live-p original-window)
                (select-window original-window))))
          (message "Opened treemacs, current window: %s" (selected-window))

          ;; Split to create cheatsheet (top) and terminal (bottom)
          (message "About to split window...")
          (let* ((top-win (selected-window))
                 (term-win (split-window-below)))
            (message "Split successful")

            ;; Set up scratch in top window (cheatsheet system removed —
            ;; discovery now via Casual / which-key / embark).
            (select-window top-win)
            (switch-to-buffer "*scratch*")
            (set-window-container top-win "Files" 'horizontal)
            (apply-container-header top-win)

            ;; Set up terminal in bottom window
            (select-window term-win)
            (when (fboundp 'eat)
              (condition-case eat-err
                  (call-interactively #'eat)
                (error
                 (message "Failed to start eat terminal: %s" (error-message-string eat-err)))))
            (set-window-container term-win "Terminals" 'horizontal)
            (apply-container-header term-win)

            ;; Start agent-shell with Claude
            (message "Attempting to start agent-shell...")
            (if (fboundp 'agent-shell-anthropic-start-claude-code)
                (condition-case agent-err
                    (progn
                      (agent-shell-anthropic-start-claude-code)
                      (message "Started agent-shell successfully"))
                  (error
                   (message "Failed to start agent-shell Claude: %s" (error-message-string agent-err))))
              (message "agent-shell-anthropic-start-claude-code function not found"))

            ;; Wait a moment for agent-shell to fully initialize
            (sit-for 0.5)

            ;; Find agent-shell's window and set its container
            (let ((agent-buffers (seq-filter (lambda (buf)
                                                (string-match-p "\\*Agent-"
                                                               (buffer-name buf)))
                                              (buffer-list))))
              (if agent-buffers
                  (progn
                    (message "Found agent-shell buffer: %s" (buffer-name (car agent-buffers)))
                    (let ((agent-window (get-buffer-window (car agent-buffers))))
                      (if agent-window
                          (progn
                            (set-window-container agent-window "Claude" 'vertical)
                            (apply-container-header agent-window)
                            (message "Agent-shell window configured"))
                        (message "Agent-shell buffer exists but no window found"))))
                (message "No agent-shell buffers found")))

            ;; Return focus to cheatsheet
            (select-window top-win)))
      (error
       (message "Error in init-window-setup: %s" (error-message-string err))))))


(add-hook 'emacs-startup-hook #'init-window-setup)

;; Option 1: Yellow border via mode-line (ACTIVE)
(defvar active-window-border-color "#eecc00")  ; Yellow from modus-vivendi
(defvar inactive-window-border-color "#535353")  ; Gray

;; Customize mode-line faces for window borders
(set-face-attribute 'mode-line nil
                    :background active-window-border-color
                    :foreground "#000000"
                    :box `(:line-width 2 :color ,active-window-border-color))
(set-face-attribute 'mode-line-inactive nil
                    :background inactive-window-border-color
                    :foreground "#888888"
                    :box nil)

;; Function to add yellow top border to active window (for windows without container headers)
(defun update-window-focus-indicator ()
  "Add yellow top border to active window if it doesn't have a container header."
  (dolist (window (window-list))
    (let ((has-container-header (window-parameter window 'container-name)))
      (with-current-buffer (window-buffer window)
        (cond
         ;; Active window without container header: add yellow border
         ((and (eq window (selected-window))
               (not has-container-header))
          (setq-local header-line-format
                      (propertize " " 'face `(:background ,active-window-border-color :height 0.3))))
         ;; Inactive window or window with container: remove our border (but keep container headers)
         ((and (not has-container-header)
               header-line-format
               (stringp header-line-format)
               (or (string-empty-p (string-trim header-line-format))
                   (string-prefix-p " " header-line-format)))
          (setq-local header-line-format nil)))))))

;; Update borders on window configuration changes
(add-hook 'window-configuration-change-hook #'update-window-focus-indicator)
(add-hook 'buffer-list-update-hook #'update-window-focus-indicator)

;; Option 3: Thicker, more visible window dividers (COMMENTED OUT)
;; (set-face-attribute 'window-divider nil
;;                     :foreground "#eecc00")  ; Yellow dividers
;; (set-face-attribute 'window-divider-first-pixel nil
;;                     :foreground "#eecc00")
;; (set-face-attribute 'window-divider-last-pixel nil
;;                     :foreground "#eecc00")
