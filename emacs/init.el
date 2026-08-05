(require 'package)

;; Configure package archives (GNU ELPA & MELPA)
(setq package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

;; Avoid TLS network handshake issues common on Windows
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

(package-initialize)

;; --- 1. AUTOMATIC PACKAGE INSTALLATION ---
;; Ensure package metadata exists before attempting to install
(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(vertico orderless corfu marginalia cape dape magit eldoc-box auctex scss-mode haskell-mode consult wgrep lsp-mode lsp-ui lsp-haskell smartparens emmet-mode))
  (unless (package-installed-p pkg)
    (condition-case nil
        (package-install pkg)
      (error
       ;; If installation fails due to an outdated MELPA index, refresh and retry once
       (package-refresh-contents)
       (package-install pkg)))))

;; --- 2. LINE NUMBERS, VISUALS & AUTOMATED TREE-SITTER ---
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq ring-bell-function 'ignore)

;; Load Modus Vivendi (Built-in Accessible Dark Theme)
(load-theme 'modus-vivendi t)

;; Force Emacs to auto-remap classic modes to modern Tree-sitter modes
(setq major-mode-remap-alist
      '((typescript-mode . typescript-ts-mode)
        (tsx-mode        . tsx-ts-mode)
        (js-mode         . js-ts-mode)
        (javascript-mode . js-ts-mode)
        (python-mode     . python-ts-mode)
        (csharp-mode     . csharp-ts-mode)
        (css-mode        . css-ts-mode)
        (html-mode       . html-ts-mode)))

;; Associate .ts and .tsx files directly with Tree-sitter modes
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src")
        (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
        (c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp" "v0.20.0")
        (json "https://github.com/tree-sitter/tree-sitter-json" "v0.20.2")
        (css "https://github.com/tree-sitter/tree-sitter-css" "v0.20.0")
        (html "https://github.com/tree-sitter/tree-sitter-html" "v0.20.1")))

(dolist (grammar treesit-language-source-alist)
  (let ((lang (car grammar)))
    (unless (treesit-language-available-p lang)
      (treesit-install-language-grammar lang))))

;; --- 3. MANUAL HOVER DOCUMENTATION ---
;; Press C-c h to display documentation popup manually at point
;; Press C-c q to close the popup frame
(global-set-key (kbd "C-c h") #'eldoc-box-help-at-point)
(global-set-key (kbd "C-c q") #'eldoc-box-quit-frame)

;; --- 4. THE IDE ENGINE (LSP Multiplexing & Language Extensions) ---
(use-package lsp-mode
  :init
  ;; Set prefix for lsp-command-keymap (e.g. C-c l r to rename, C-c l a for code actions)
  (setq lsp-keymap-prefix "C-c l")
  :hook ((python-mode
          python-ts-mode
          csharp-mode
          csharp-ts-mode
          typescript-mode
          typescript-ts-mode
          tsx-mode
          tsx-ts-mode
          js-mode
          js-ts-mode
          js2-mode
          html-mode
          html-ts-mode
          mhtml-mode
          css-mode
          css-ts-mode
          scss-mode) . lsp-deferred)
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-disabled-clients nil)

  ;; Configure default TypeScript client settings
  (setq lsp-clients-typescript-init-opts '(:importModuleSpecifierPreference "relative"))

  ;; Fully disable LSP modeline indicators to fix crashes
  (setq lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-modeline-workspace-status-enable nil)

  ;; Fix lsp--on-idle timer & hash-table race conditions
  (setq lsp-idle-delay 0.5
        lsp-log-io nil
        lsp-completion-provider :capf          ; Standard Completion At Point Function
        lsp-completion-filter-on-kind nil      ; Do NOT let LSP filter out keyword candidates
        lsp-enable-on-type-formatting nil       ; Disable idle background formatting edits
        lsp-enable-indentation nil             ; Prevents background indent checks
        lsp-enable-snippet t
        lsp-completion-enable-additional-text-edit t
        lsp-completion-show-detail t
        lsp-completion-show-kind t
        lsp-enable-symbol-highlighting nil     ; Stops idle symbol highlights
        lsp-completion-no-auto-import nil
        lsp-response-timeout 10)

  ;; Prevent lsp--on-idle timer errors when server is stopped or uninitialized
  (advice-add 'lsp--on-idle :around
              (lambda (orig-fun &rest args)
                (when (and (bound-and-true-p lsp-mode)
                           (lsp-workspaces))
                  (ignore-errors (apply orig-fun args)))))

  ;; Enable Orderless fuzzy completion for LSP results
  (defun my/lsp-mode-setup-completion ()
    (setq-local completion-category-defaults nil)
    (setq-local completion-styles '(orderless flex basic)))
  (add-hook 'lsp-mode-hook #'my/lsp-mode-setup-completion))

;; --- 4b. WORKAROUND: auto-create missing `bin/tsserver` shim ---
;; Recent `typescript` npm releases no longer ship a `bin/tsserver` entry
;; in their package.json, so npm never creates the executable shim that
;; lsp-mode's ts-ls client expects at
;; <lsp-server-install-dir>/npm/typescript/bin/tsserver
;; This self-heals that on any machine, as long as `M-x lsp-install-server
;; RET ts-ls RET` (or the first lsp-deferred trigger) has downloaded the
;; `typescript` package into lsp-mode's cache.
(defun my/lsp-ensure-tsserver-shim ()
  "Create a `tsserver' executable shim for lsp-mode's managed typescript
install, if the managed `typescript' package exists but is missing its
`bin/tsserver' entry."
  (let* ((ts-dir (expand-file-name "npm/typescript" lsp-server-install-dir))
         (bin-dir (expand-file-name "bin" ts-dir))
         (shim (expand-file-name "tsserver" bin-dir))
         (target (expand-file-name
                  "lib/node_modules/typescript/lib/tsserver.js" ts-dir)))
    (when (and (file-exists-p target)
               (not (file-executable-p shim)))
      (make-directory bin-dir t)
      (with-temp-file shim
        (insert "#!/usr/bin/env bash\n")
        (insert (format "exec node \"%s\" \"$@\"\n" target)))
      (set-file-modes shim #o755)
      (message "lsp-mode: created missing tsserver shim at %s" shim))))

(defun my/lsp--npm-dependency-path-advice (orig-fun &rest args)
  "Retry ORIG-FUN once after attempting to create a missing tsserver shim."
  (condition-case _err
      (apply orig-fun args)
    (error
     (my/lsp-ensure-tsserver-shim)
     (apply orig-fun args))))

(with-eval-after-load 'lsp-mode
  (advice-add 'lsp--npm-dependency-path :around
              #'my/lsp--npm-dependency-path-advice))

(use-package lsp-ui
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-delay 0.2
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-enable nil
        lsp-ui-sideline-show-diagnostics nil
        lsp-ui-sideline-show-hover nil))

;; Haskell Language Server Integration
(use-package lsp-haskell
  :hook (haskell-mode . lsp-deferred))

;; Angular Language Server Integration
(use-package lsp-angular
  :ensure nil
  :hook ((typescript-mode
          typescript-ts-mode
          html-mode
          html-ts-mode) . lsp-deferred)
  :config
  (setq lsp-clients-angular-language-server-command
        '("ngserver"
          "--stdio"
          "--tsProbeLocations" "/usr/local/lib/node_modules,./node_modules,/usr/lib/node_modules"
          "--ngProbeLocations" "/usr/local/lib/node_modules,./node_modules,/usr/lib/node_modules")))

;; --- EMMET & AUTOMATIC HTML TAG EXPANSION ---
(use-package emmet-mode
  :hook ((html-mode . emmet-mode)
         (html-ts-mode . emmet-mode)
         (mhtml-mode . emmet-mode)
         (web-mode . emmet-mode)
         (tsx-ts-mode . emmet-mode))
  :config
  (setq emmet-move-cursor-after-expanding t
        emmet-self-closing-tag-style "html")
  ;; Bind TAB explicitly to expand Emmet snippets
  (define-key emmet-mode-keymap (kbd "TAB") #'emmet-expand-line)
  (define-key emmet-mode-keymap (kbd "<tab>") #'emmet-expand-line))

(use-package smartparens
  :hook ((html-mode . smartparens-mode)
         (html-ts-mode . smartparens-mode)
         (mhtml-mode . smartparens-mode)
         (web-mode . smartparens-mode)
         (tsx-ts-mode . smartparens-mode))
  :config
  (require 'smartparens-html)
  (smartparens-global-mode t)
  (sp-with-modes '(html-mode html-ts-mode mhtml-mode web-mode tsx-ts-mode)
    (sp-local-pair "<" ">" :actions '(insert wrap))))

;; --- 5. AUTOCOMPLETE, POPUPS & ANGULAR INTERPOLATION ---
(use-package corfu
  :init
  (global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.02           ; Faster popup delay
        corfu-auto-prefix 1
        corfu-popupinfo-mode t   ; Required: Shows method/function docs inside the completion menu
        corfu-preview-current nil)      ; Don't insert preview while typing

  ;; Ensure TAB selects/accepts corfu candidate smoothly
  (define-key corfu-map (kbd "TAB") #'corfu-complete)
  (define-key corfu-map (kbd "<tab>") #'corfu-complete))

(use-package cape
  :init
  ;; Supercharge LSP completion by merging it with Cape's keyword table
  (defun my/setup-lsp-capf-super ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super
                        #'lsp-completion-at-point
                        #'cape-keyword
                        #'cape-dabbrev))))

  ;; Run at depth 90 to ensure this overrides lsp-mode's default CAPF backend
  (add-hook 'lsp-mode-hook #'my/setup-lsp-capf-super 90))

;; --- 6. FUZZY SEARCH & TELESCOPE EQUIVALENTS ---
(vertico-mode 1)
(use-package orderless
  :init
  (setq completion-styles '(orderless flex basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))
(marginalia-mode 1)

;; Consult (Telescope-like live searching & navigation)
(use-package consult
  :bind (;; Search content in project (like Telescope live_grep)
         ("C-c f g" . consult-ripgrep)
         ("C-c s r" . consult-ripgrep)
         
         ;; Search content in current buffer (like Telescope current_buffer_fuzzy_find)
         ("C-s"     . consult-line)
         
         ;; Find files in project (like Telescope find_files)
         ("C-c f f" . consult-fd)
         
         ;; Switch buffers with preview (like Telescope buffers)
         ("C-x b"   . consult-buffer)))

;; Wgrep (Allows editing ripgrep search results directly in the buffer)
(use-package wgrep
  :config
  (setq wgrep-auto-save-buffer t))

;; --- 7. WINDOW & PROJECT MANAGEMENT ---
(use-package windmove
  :ensure nil
  :config
  ;; Maak een nieuwe keymap aan voor alle acties onder M-m
  (define-prefix-command 'mijn-venster-map)
  (global-set-key (kbd "M-m") 'mijn-venster-map)

  ;; A. Navigeren tussen vensters (Windmove hjkl)
  (define-key mijn-venster-map (kbd "h") 'windmove-left)
  (define-key mijn-venster-map (kbd "j") 'windmove-down)
  (define-key mijn-venster-map (kbd "k") 'windmove-up)
  (define-key mijn-venster-map (kbd "l") 'windmove-right)

  ;; B. Vensters splitsen
  (define-key mijn-venster-map (kbd "v") 'split-window-right)  ; 'v' van Verticaal
  (define-key mijn-venster-map (kbd "s") 'split-window-below)  ; 's' van Splitsen/Horizontaal

  ;; C. Vensters sluiten
  (define-key mijn-venster-map (kbd "x") 'delete-window)        ; 'x' sluit huidige venster
  (define-key mijn-venster-map (kbd "o") 'delete-other-windows) ; 'o' behoudt Only dit venster

  ;; D. Projectbeheer (Voor Angular & .NET isolatie)
  (define-key mijn-venster-map (kbd "p p") 'project-switch-project) ; Wissel tussen Angular en .NET
  (define-key mijn-venster-map (kbd "p f") 'project-find-file)       ; Zoek bestand binnen huidig project
  (define-key mijn-venster-map (kbd "p s") 'project-shell))         ; Open terminal voor dit specifieke project

;; --- 8. DEBUGGER CONFIGURATION (Dape) ---
(use-package dape
  :ensure nil
  :bind (("C-c d d" . dape)                     ; Safe custom prefix to avoid Dired conflicts
         ("C-c d b" . dape-breakpoint-toggle))
  :config
  (setq dape-buffer-window-arrangement 'right)

  ;; Python Configuration
  (add-to-list 'dape-configs
                `(debugpy
                  modes (python-mode python-ts-mode)
                  command "python3"
                  args ("-m" "debugpy.adapter")
                  :type "executable"
                  :request "launch"
                  :program dape-buffer-default))

  ;; HASKELL DEBUGGER ARCHITECTURE (Using the native GHC GHCi DAP provider)
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
                  :ghciEnv ,(make-hash-table)             ; Evaluates to an empty JSON object {}
                  :internalConsoleOptions "neverOpen")))

;; --- 9. GLOBAL KEYBINDINGS ---
(global-set-key (kbd "C-c r")   'restart-emacs)
(global-set-key (kbd "C-x g")   'magit-status)

;; --- 10. MAGIT LINE NUMBERS ---
;; Allow line numbers inside Magit but target only active diff buffers
(setq magit-section-disable-line-numbers nil)
(add-hook 'magit-diff-mode-hook
          (lambda ()
            (setq display-line-numbers-type t) ; Force absolute mode globally for this buffer
            (display-line-numbers-mode 1)))

;; ADD LINE NUMBERS FOR MAGIT STATUS BUFFER:
(add-hook 'magit-status-mode-hook
          (lambda ()
            (setq display-line-numbers-type t)
            (display-line-numbers-mode 1)))

;; --- 11. EDIFF / MAGIT SIDE-BY-SIDE DIFF CONFIGURATION ---
;; Force Ediff to split windows side-by-side horizontally instead of stacked vertically
(setq ediff-split-window-function 'split-window-horizontally)
;; Keep the Ediff control panel inside the same frame instead of opening a separate mini-frame
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
;; Force magit-ediff-dwim ('e') to prefer 2-way side-by-side diffs over 3-way diffs
(setq magit-ediff-dwim-show-on-hunks t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )