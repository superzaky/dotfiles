;;; init-tools.el --- Magit, Diff-hl, Ediff & Dape Debugger -*- lexical-binding: t; -*-

;; --- DIFF-HL (GIT GUTTER) ---
(use-package diff-hl
  :ensure t
  :init
  (global-diff-hl-mode 1)
  :config
  (diff-hl-flydiff-mode 1))
  ;; Commented out to avoid extra git.exe calls during Magit refreshes:
  ;; (with-eval-after-load 'magit
  ;;   (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
  ;;   (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

;; --- MAGIT ---
(global-set-key (kbd "C-x g") 'magit-status)

(setq magit-section-disable-line-numbers nil)
(add-hook 'magit-diff-mode-hook
          (lambda ()
            (setq display-line-numbers-type t)
            (display-line-numbers-mode 1)))

(add-hook 'magit-status-mode-hook
          (lambda ()
            (setq display-line-numbers-type t)
            (display-line-numbers-mode 1)))

(with-eval-after-load 'magit
  (define-key magit-mode-map (kbd "M-RET") #'magit-diff-visit-file-other-window)

  ;; Keep diff rendering lightweight
  (setq magit-diff-refine-hunk nil)
  (setq magit-diff-fontify-hunk t)
  (setq magit-diff-specify-hunk-foreground t)
  (setq magit-diff-use-indicator-faces t)

  ;; --- PERFORMANCE: MINIMIZE GIT.EXE CALLS ON LOCKED-DOWN WINDOWS ---
  (remove-hook 'magit-status-headers-hook #'magit-insert-tags-header)
  (remove-hook 'magit-status-headers-hook #'magit-insert-push-branch-header)
  (remove-hook 'magit-status-headers-hook #'magit-insert-diff-filter-header)

  (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-upstream-or-recent)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-upstream)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-pushremote)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-pushremote)
  (remove-hook 'magit-status-sections-hook #'magit-insert-stashes)
  (remove-hook 'magit-status-sections-hook #'magit-insert-merge-log)

  ;; Only refresh magit-status when running Magit commands or pressing 'g'
  (setq magit-refresh-status-buffer nil)

  ;; Turn off verbose logging now that benchmarking is done
  (setq magit-refresh-verbose nil))

;; --- EDIFF ---
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq magit-ediff-dwim-show-on-hunks t)

;; --- DAPE (DEBUGGER) ---
(use-package dape
  :ensure nil
  :bind (("C-c d d" . dape)
         ("C-c d b" . dape-breakpoint-toggle))
  :config
  (setq dape-buffer-window-arrangement 'right)

  (add-to-list 'dape-configs
                `(debugpy
                  modes (python-mode python-ts-mode)
                  command "python3"
                  args ("-m" "debugpy.adapter")
                  :type "executable"
                  :request "launch"
                  :program dape-buffer-default))

  (add-to-list 'dape-configs
                `(haskell-debug
                  modes (haskell-mode)
                  command "haskell-debug-adapter"
                  :type "executable"
                  :request "launch"
                  :name "Haskell Dape"
                  :workspace dape-cwd
                  :startup dape-buffer-default
                  :ghciCmd "cabal repl -w ghci-dap --repl-no-load"
                  :ghciPrompt "H>>= "
                  :ghciInitialPrompt "> "
                  :logLevel "WARNING"
                  :logFile "/tmp/hda.log"
                  :stopOnEntry nil
                  :forceInspect nil
                  :startupFunc ""
                  :startupArgs ""
                  :mainArgs ""
                  :ghciEnv ,(make-hash-table)
                  :internalConsoleOptions "neverOpen")))

;; Restart Emacs shortcut
(global-set-key (kbd "C-c r") 'restart-emacs)

(provide 'init-tools)
