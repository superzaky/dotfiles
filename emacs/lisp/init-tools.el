;;; init-tools.el --- Magit, Diff-hl, Ediff & Dape Debugger -*- lexical-binding: t; -*-

;; --- DIFF-HL (GIT GUTTER) ---
(use-package diff-hl
  :ensure t
  :init
  (global-diff-hl-mode 1)
  :config
  (diff-hl-flydiff-mode 1)
  (with-eval-after-load 'magit
    (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

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
  (setq magit-diff-refine-hunk 'all)
  (setq magit-diff-fontify-hunk t)
  (setq magit-diff-specify-hunk-foreground t)
  (setq magit-diff-use-indicator-faces t))

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