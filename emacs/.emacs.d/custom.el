(use-package emacs
  :init
  (defalias 'yes-or-no-p 'y-or-n-p) ;; life is too short

  (setq indent-tabs-mode nil) ;; no tabs

  (setq make-backup-files nil) ;; keep everything under vc 
  (setq auto-save-default nil)

  ;; keep backup and save files in a dedicated directory
  (setq backup-directory-alist
        `((".*" . ,(concat user-emacs-directory "backups")))
        auto-save-file-name-transforms
        `((".*" ,(concat user-emacs-directory "backups") t)))

  ;; keep undo tree cache in a dedicated directory
  (setq undo-tree-history-directory-alist
	`((".*" . ,(concat user-emacs-directory "undo"))))

  ;; no need to create lockfiles
  (setq create-lockfiles nil))

(setq window-resize-pixelwise t)
(setq frame-resize-pixelwise t)

;; Mouse Support in Terminal
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; Set default font face
(set-face-attribute 'default nil :font "Source Code Pro")

;; Load theme
(load-theme 'modus-vivendi t)

;; Disable package.el in favor of straight.el
(setq package-enable-at-startup nil)

;; Disable splash screen
(setq inhibit-startup-screen t)

;; Disable sounds
(setq ring-bell-function 'ignore)

;; Install vertico
(use-package vertico
  :straight t
  :ensure t
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))

;; Configure vertico directory extension.
(use-package vertico-directory
  :straight nil
  ;; https://github.com/radian-software/straight.el/issues/819
  :load-path "straight/build/vertico/extensions"
  ;; More convenient directory navigation commands
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; Install savehist
(use-package savehist
  :straight t
  :init
  (savehist-mode))

;; Install marginalia
(use-package marginalia
  :straight t
  :after vertico
  :ensure t
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode))

;; Install Dashboard
(use-package dashboard
  :straight t
  :ensure t
  :config
  (dashboard-setup-startup-hook))

;; Install golden-ratio
(use-package golden-ratio
  :straight t
  :init
  (golden-ratio-mode 1))

;; Install consult
(use-package consult
  :straight t)

;; FIXME
(global-set-key [rebind switch-to-buffer] #'consult-buffer)
(global-set-key (kbd "C-c j") #'consult-line)
(global-set-key (kbd "C-c i") #'consult-imenu)
(setq read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t
      completion-ignore-case t)

;; Install corfu
(use-package orderless
  :straight t)

;; https://github.com/minad/corfu#auto-completion
;;(defun orderless-fast-dispatch (word index total)
;;  (and (= index 0) (= total 1) (length< word 4)
;;       `(orderless-regexp . ,(concat "^" (regexp-quote word)))))

;;(orderless-define-completion-style orderless-fast
;;  (orderless-style-dispatchers '(orderless-fast-dispatch))
;;  (orderless-matching-styles '(orderless-literal orderless-regexp)))

(use-package corfu-terminal
  :straight t
  ;; Optional customizations
  :custom
  (corfu-cycle t)                 ; Allows cycling through candidates
  (corfu-auto t)                  ; Enable auto completion
  (corfu-auto-prefix 0)
  (corfu-auto-delay 0)
  (completion-styles '(basic))
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-preview-current 'insert) ; Do not preview current candidate
  (corfu-preselect-first nil)
  (corfu-on-exact-match nil)      ; Don't auto expand tempel snippets
  (corfu-quit-no-match t)

  ;; Optionally use TAB for cycling, default is `corfu-complete'.
  :bind (:map corfu-map
              ("M-SPC"      . corfu-insert-separator)
              ;;("TAB"        . corfu-next)
              ;;([tab]        . corfu-next)
              ;;("S-TAB"      . corfu-previous)
              ;;([backtab]    . corfu-previous)
              ("S-<return>" . corfu-insert)
              ("RET"        . nil))
  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.
  ;; This is recommended since Dabbrev can be used globally (M-/).
  ;; See also `corfu-excluded-modes'.
  :init
  (global-corfu-mode)
  (unless (display-graphic-p)
    (corfu-terminal-mode +1))

  :config
  (add-hook 'eshell-mode-hook
            (lambda () (setq-local corfu-quit-at-boundary t
                              corfu-quit-no-match t
                              corfu-auto nil)
              (corfu-mode))))

(use-package emacs
  :init
  ;; TAB cycle if there are only few candidates
  (setq completion-cycle-threshold 3)

  ;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
  ;; Corfu commands are hidden, since they are not supposed to be used via M-x.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (setq tab-always-indent 'complete))

;; Install lsp-mode
;; https://github.com/minad/corfu/wiki#configuring-corfu-for-lsp-mode

(use-package orderless
  :straight t
  :init
  ;; Tune the global completion style settings to your liking!
  ;; This affects the minibuffer and non-lsp completion at point.
  (setq completion-styles '(orderless partial-completion basic)
        completion-category-defaults nil
        completion-category-overrides nil))

(use-package lsp-mode
  :straight t
  :custom
  (lsp-completion-provider :none) ;; we use Corfu!
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
  (add-to-list 'completion-at-point-functions #'cape-symbol)
  (add-to-list 'completion-at-point-functions #'cape-line))

;; Install magit -  Git client
(use-package magit
  :straight t)

;; Bind the `magit-status' command to a convenient key.
(global-set-key (kbd "C-c g") #'magit-status)

;; Install diff-hl - Indication of local VCS changes
(use-package diff-hl
  :straight t)

;; Install wind-move - Select window with Shift+<arrow>
(use-package windmove
  :straight t)

(windmove-default-keybindings 'ctrl)

;; Enable `diff-hl' support by default in programming buffers
(add-hook 'prog-mode-hook #'diff-hl-mode)

;; Install expand-region
(use-package expand-region
  :straight t)
(global-set-key (kbd "M-2") 'er/expand-region)

;;; Install undo-tree
(use-package undo-tree
  :straight t)
(global-undo-tree-mode 1)

;; Install go-mode - Golang Support
(use-package go-mode
  :straight t)

;; Set up before-save hooks to format buffer and add/delete imports.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;;(use-package flycheck-golangci-lint
;;  :straight t
;;  :ensure t
;;  :hook (go-mode . flycheck-golangci-lint-setup))

;; Enable lsp-mode for go buffers
(add-hook 'go-mode-hook 'lsp-deferred)

;; Install yaml-mode
(use-package yaml-mode
  :straight t)

;; Install json-mode
(use-package json-mode
  :straight t)

;; Install typescript mode
(use-package typescript-mode
  :straight t)

;; Install docker-mode
(use-package dockerfile-mode
  :straight t)

;; Install markdown-mode
(use-package markdown-mode
  :straight t)

;; Install flycheck - Syntax Checking
(use-package flycheck
  :straight t
  :defer 2
  :diminish
  :ensure t
  :custom
  (flycheck-display-errors-delay .3)
  :init
  (global-flycheck-mode))

;; Install treemacs
(use-package treemacs
  :straight t
  :ensure t
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (progn
    (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
          treemacs-deferred-git-apply-delay        0.5
          treemacs-directory-name-transformer      #'identity
          treemacs-display-in-side-window          t
          treemacs-eldoc-display                   'simple
          treemacs-file-event-delay                2000
          treemacs-file-extension-regex            treemacs-last-period-regex-value
          treemacs-file-follow-delay               0.2
          treemacs-file-name-transformer           #'identity
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
          treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask")
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
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag)))

(use-package treemacs-magit
  :straight t
  :after (treemacs magit)
  :ensure t)
