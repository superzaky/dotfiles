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

(dolist (pkg '(vertico orderless corfu marginalia cape dape magit eldoc-box auctex scss-mode haskell-mode consult wgrep lsp-mode lsp-ui lsp-haskell smartparens emmet-mode dashboard))
  (unless (package-installed-p pkg)
    (condition-case nil
        (package-install pkg)
      (error
       ;; If installation fails due to an outdated MELPA index, refresh and retry once
       (package-refresh-contents)
       (package-install pkg)))))

;; --- 2. LINE NUMBERS, VISUALS & AUTOMATED TREE-SITTER ---
(global-display-line-numbers-mode t)
;;(setq display-line-numbers-type 'relative)
(setq ring-bell-function 'ignore)

;; Overwrite active selection when typing or pasting (C-y after C-x h)
(delete-selection-mode 1)

;; --- 2b. INDENTATION: SPACES INSTEAD OF TABS ---
;; Use spaces instead of literal tab characters for indentation, globally.
;; (indent-tabs-mode is buffer-local in most programming modes, so this
;; must be setq-default, not setq, to apply everywhere.)
(setq-default indent-tabs-mode nil)

;; Set consistent 2-space indent widths per language (matches typical
;; Prettier/Angular/ESLint conventions)
(setq-default typescript-ts-mode-indent-offset 2
              js-indent-level 2
              css-indent-offset 2
              sgml-basic-offset 2      ; used by html-mode/mhtml-mode
              web-mode-markup-indent-offset 2)

;; Haskell conventionally uses its own indentation style
(setq-default haskell-indent-offset 2)

;; --- 2c. VS CODE-STYLE TAB / SHIFT-TAB ---
;; By default, indent-for-tab-command only moves a line to its single
;; "correct" position and then stops doing anything further. VS Code instead
;; lets you keep pressing TAB to indent one level further even once the line
;; is already correctly indented. This replicates that behavior, and adds
;; Shift-TAB (<backtab>) as the matching "un-indent one level" companion.
(defun my/tab-or-indent-more ()
  "Indent line to the correct position; if already there (or called
repeatedly in a row), keep indenting one level further each time,
matching VS Code's TAB behavior."
  (interactive)
  (if (memq last-command '(my/tab-or-indent-more my/emmet-tab-or-indent))
      ;; Repeated TAB press: skip smart-indent recalculation (which would
      ;; snap the line back to its "correct" position) and just add another
      ;; indent level.
      (indent-line-to (+ (current-indentation) tab-width))
    (let ((prev-indent (current-indentation)))
      (indent-for-tab-command)
      (when (= prev-indent (current-indentation))
        (indent-line-to (+ prev-indent tab-width))))))

(defun my/backtab-unindent ()
  "Un-indent the current line by one indent step."
  (interactive)
  (indent-line-to (max 0 (- (current-indentation) tab-width))))

(global-set-key (kbd "TAB") #'my/tab-or-indent-more)
(global-set-key (kbd "<backtab>") #'my/backtab-unindent)

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

;; Associate .ts, .html, and .tsx files directly with Tree-sitter modes
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.html\\'" . html-ts-mode))

;; Updated to master branches to prevent ABI mismatches with system libtree-sitter (0.22+)
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (python "https://github.com/tree-sitter/tree-sitter-python" "master")
        (c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp" "master")
        (json "https://github.com/tree-sitter/tree-sitter-json" "master")
        (css "https://github.com/tree-sitter/tree-sitter-css" "master")
        (html "https://github.com/tree-sitter/tree-sitter-html" "master")))

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
  ;; Disable html-ls so angular-ls takes over .html files in Angular projects
  (setq lsp-disabled-clients '(html-ls))

  ;; Cross-platform executable path fixes for Windows (.cmd / .bat resolving)
  (when (eq system-type 'windows-nt)
    (setq lsp-clients-typescript-server "typescript-language-server")
    (setq lsp-clients-typescript-command '("typescript-language-server.cmd" "--stdio")))

  (setq lsp-clients-typescript-init-opts '(:importModuleSpecifierPreference "relative"))

  ;; Modeline configuration
  (setq lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-modeline-workspace-status-enable nil)

  ;; Performance & completion behavior settings
  (setq lsp-idle-delay 0.2
        lsp-log-io nil
        lsp-completion-provider :capf  ; Standard Completion At Point Function
        lsp-completion-filter-on-kind nil  ; Do NOT let LSP filter out keyword candidates
        lsp-enable-on-type-formatting nil   ; Disable idle background formatting edits
        lsp-enable-indentation nil   ; Prevents background indent checks
        lsp-enable-snippet t
        lsp-completion-enable-additional-text-edit t
        lsp-completion-show-detail t
        lsp-completion-show-kind t
        lsp-enable-symbol-highlighting t ; Enables automatic function/symbol occurrences highlighting
        lsp-completion-no-auto-import nil
        lsp-response-timeout 10)

  ;; Prevent lsp--on-idle timer crashes
  (advice-add 'lsp--on-idle :around
              (lambda (orig-fun &rest args)
                (when (and (bound-and-true-p lsp-mode)
                           (lsp-workspaces))
                  (ignore-errors (apply orig-fun args)))))

  ;; Enable Orderless fuzzy completion for LSP candidates
  (defun my/lsp-mode-setup-completion ()
    (setq-local completion-category-defaults nil)
    (setq-local completion-styles '(orderless flex basic)))
  (add-hook 'lsp-mode-hook #'my/lsp-mode-setup-completion))

;; --- 4b. WORKAROUND: Auto-create missing `bin/tsserver` shim ---
(defun my/lsp-ensure-tsserver-shim ()
  "Create a `tsserver' executable shim for lsp-mode's managed typescript
install if missing on Windows or Unix."
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

;; --- ANGULAR LANGUAGE SERVER CONFIGURATION ---
(use-package lsp-angular
  :ensure nil
  :hook ((typescript-mode
          typescript-ts-mode
          html-mode
          html-ts-mode
          mhtml-mode) . lsp-deferred)
  :config
  (defun my/lsp-angular-get-probe-locations ()
    "Gather node_modules paths from active workspace root, current directory, and global npm."
    (let* ((proj-root (or (lsp-workspace-root)
                          (and (fboundp 'project-root)
                               (project-current)
                               (project-root (project-current)))
                          default-directory))
           (local-node (expand-file-name "node_modules" proj-root))
           (global-node (expand-file-name "npm/node_modules" (getenv "APPDATA"))))
      (delq nil (mapcar (lambda (path)
                          (when (and path (file-directory-p path)) path))
                        (list local-node global-node)))))

  (defun my/lsp-angular-command-advice (&rest _args)
    (let* ((probes (my/lsp-angular-get-probe-locations))
           (ng-cmd (if (eq system-type 'windows-nt) "ngserver.cmd" "ngserver"))
           (cmd-args `(,ng-cmd "--stdio")))
      (dolist (loc probes)
        (setq cmd-args (append cmd-args `("--tsProbeLocations" ,loc
                                          "--ngProbeLocations" ,loc))))
      (setq lsp-clients-angular-language-server-command cmd-args)))

  (advice-add 'lsp-angular--create-connection :before #'my/lsp-angular-command-advice)
  (setq lsp-angular-suggest-use-minimal-type-imports t))

;; --- HTML MATCHING TAG HIGHLIGHT ---
;; When point is inside an opening or closing HTML tag (e.g. <div> or
;; </div>), highlight the tag name in BOTH the opening and closing tag of
;; that element. Works for any element, not just div, since it walks the
;; tree-sitter parse tree rather than matching specific tag names.
(defface my/matching-tag-face
  '((t :inherit highlight :weight bold))
  "Face used to highlight the matching opening/closing HTML tag name.")

(defvar-local my/tag-match-overlays nil)

(defun my/tag-match--clear ()
  (mapc #'delete-overlay my/tag-match-overlays)
  (setq my/tag-match-overlays nil))

(defun my/tag-match--node-by-type (node type)
  "Return the first child of NODE whose tree-sitter type is TYPE."
  (and node
       (seq-find (lambda (c) (equal (treesit-node-type c) type))
                 (treesit-node-children node))))

(defun my/tag-match--highlight-node (node)
  (when node
    (let ((ov (make-overlay (treesit-node-start node) (treesit-node-end node))))
      (overlay-put ov 'face 'my/matching-tag-face)
      (push ov my/tag-match-overlays))))

(defun my/highlight-matching-tag ()
  "Highlight the tag-name pair for the HTML element point is currently
inside a start_tag or end_tag of."
  (my/tag-match--clear)
  (when (and (derived-mode-p 'html-ts-mode)
             (treesit-parser-list))
    (let* ((node (treesit-node-at (point)))
           (tag-node (and node
                          (treesit-parent-until
                           node
                           (lambda (n) (member (treesit-node-type n)
                                                '("start_tag" "end_tag")))
                           t)))
           (element (and tag-node (treesit-node-parent tag-node))))
      (when (and element (equal (treesit-node-type element) "element"))
        (let ((start-tag (my/tag-match--node-by-type element "start_tag"))
              (end-tag (my/tag-match--node-by-type element "end_tag")))
          (my/tag-match--highlight-node
           (my/tag-match--node-by-type start-tag "tag_name"))
          (my/tag-match--highlight-node
           (my/tag-match--node-by-type end-tag "tag_name")))))))

(define-minor-mode my/highlight-matching-tag-mode
  "Highlight the matching opening/closing HTML tag pair around point."
  :lighter nil
  (if my/highlight-matching-tag-mode
      (add-hook 'post-command-hook #'my/highlight-matching-tag nil t)
    (remove-hook 'post-command-hook #'my/highlight-matching-tag t)
    (my/tag-match--clear)))

(add-hook 'html-ts-mode-hook #'my/highlight-matching-tag-mode)

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

  ;; FIX: TAB should only expand an Emmet abbreviation when one is actually
  ;; present at point. Otherwise it must fall back to normal indentation,
  ;; or you lose the ability to indent entirely in html/tsx buffers.
  ;; NOTE: falls back to my/tab-or-indent-more (defined in section 2c) so
  ;; that html/web buffers get the same "indent further if already correct"
  ;; behavior as everywhere else, instead of doing nothing on already-correct
  ;; lines.
  (defun my/emmet-tab-or-indent ()
    "Expand Emmet abbreviation at point if there is one, otherwise indent."
    (interactive)
    (if (and (bound-and-true-p emmet-mode)
             (emmet-expr-on-line))
        (emmet-expand-line nil)
      (my/tab-or-indent-more)))

  ;; Bind TAB to the smart fallback instead of unconditionally expanding
  (define-key emmet-mode-keymap (kbd "TAB") #'my/emmet-tab-or-indent)
  (define-key emmet-mode-keymap (kbd "<tab>") #'my/emmet-tab-or-indent))

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
    (sp-local-pair "<" ">" :actions '(insert wrap))
    (sp-local-pair "{{" "}}" :post-handlers '("| "))
    (sp-local-pair "{" "}" :unless '(sp-in-string-p))))

;; --- 5. AUTOCOMPLETE, POPUPS & CORFU/CAPE CAPF INTEGRATION ---
(use-package corfu
  :init
  (global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.05
        corfu-auto-prefix 1
        corfu-popupinfo-mode t
        corfu-preview-current nil
        corfu-quit-no-match 'separator
        corfu-quit-at-boundary nil)

  ;; FIX: Corfu does NOT bind TAB by default, and for good reason -- while the
  ;; completion popup is visible, corfu-map takes priority over every other
  ;; keymap (including the major mode's indent binding). Because
  ;; global-corfu-mode is active everywhere and the popup pops up almost
  ;; instantly (corfu-auto-delay 0.05, corfu-auto-prefix 1), binding TAB here
  ;; hijacks indentation in EVERY buffer, in every language, any time the
  ;; popup happens to be showing. That's why it was breaking indentation in
  ;; html, ts, and haskell files alike.
  ;;
  ;; Use a different key to accept/insert the selected candidate, and leave
  ;; TAB alone so it always falls through to indent-for-tab-command.
  (define-key corfu-map (kbd "C-<tab>") #'corfu-insert)
  (define-key corfu-map (kbd "RET") #'corfu-insert))

(use-package cape
  :init
  (defun my/setup-lsp-capf-super ()
    "Configure completion-at-point-functions safely for LSP and Cape."
    (setq-local completion-at-point-functions
                (list #'lsp-completion-at-point
                      #'cape-dabbrev
                      #'cape-keyword)))

  (setq cape-dabbrev-check-other-buffers t)
  ;; Run at depth 90 to ensure this overrides lsp-mode's default CAPF backend
  (add-hook 'lsp-mode-hook #'my/setup-lsp-capf-super 90))

;; --- 6. FUZZY SEARCH & TELESCOPE EQUIVALENTS ---
(vertico-mode 1)
(use-package orderless
  :init
  (setq completion-styles '(orderless flex basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion))
                                        (lsp-capf (styles basic orderless)))))
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

;; --- 7. WINDOW, PROJECT & FILE MANAGEMENT ---
(use-package dired
  :ensure nil
  :config
  (require 'dired-x)
  ;; Prevent spawning a new buffer for every visited directory
  (setq dired-kill-when-opening-new-dired-buffer t)
  :bind (("C-x C-j" . dired-jump)))

(use-package windmove
  :ensure nil
  :config
  (windmove-default-keybindings 'meta)
  ;; Maak een nieuwe keymap aan voor alle acties onder M-m
  (define-prefix-command 'mijn-venster-map)
  (global-set-key (kbd "M-m") 'mijn-venster-map)

  ;; A. Navigeren tussen vensters (Windmove hjkl)
  ;; (define-key mijn-venster-map (kbd "h") 'windmove-left)
  ;; (define-key mijn-venster-map (kbd "j") 'windmove-down)
  ;; (define-key mijn-venster-map (kbd "k") 'windmove-up)
  ;; (define-key mijn-venster-map (kbd "l") 'windmove-right)

  ;; B. Vensters splitsen
  (define-key mijn-venster-map (kbd "v") 'split-window-right) ; 'v' van Verticaal
  (define-key mijn-venster-map (kbd "s") 'split-window-below) ; 's' van Splitsen/Horizontaal

  ;; C. Vensters sluiten
  (define-key mijn-venster-map (kbd "x") 'delete-window)        ; 'x' sluit huidige venster
  (define-key mijn-venster-map (kbd "o") 'delete-other-windows) ; 'o' behoudt Only dit venster

  ;; D. Projectbeheer (Voor Angular & .NET isolatie)
  (define-key mijn-venster-map (kbd "p p") 'project-switch-project) ; Wissel tussen Angular en .NET
  (define-key mijn-venster-map (kbd "p f") 'project-find-file)       ; Zoek bestand binnen huidig project
  (define-key mijn-venster-map (kbd "p s") 'project-shell))          ; Open terminal voor dit specifieke project

;; Copy current filename / path helper
(defun my/copy-current-file-name (&optional arg)
  "Copy the filename of the current buffer to the clipboard/kill-ring.
With prefix argument ARG (C-u C-c f c), copy the full file path instead."
  (interactive "P")
  (if-let ((path (buffer-file-name)))
      (let ((result (if arg path (file-name-nondirectory path))))
        (kill-new result)
        (message "Copied %s to clipboard: %s"
                 (if arg "full path" "filename")
                 result))
    (user-error "Current buffer is not visiting a file")))

(global-set-key (kbd "C-c f c") #'my/copy-current-file-name)

;; Copy line or region
(defun copy-line-or-region ()
  "Copy current line if no region is active."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (kill-ring-save (line-beginning-position) (line-beginning-position 2))
    (message "Copied line")))

(global-set-key (kbd "M-w") 'copy-line-or-region)

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

;; --- 10b. MAGIT: VISIT FILE IN OTHER WINDOW & WORD-LEVEL DIFF HIGHLIGHTING ---
(with-eval-after-load 'magit
  ;; 'o' is already taken by the Submodule prefix, so use M-RET instead to
  ;; visit the file at point (from status, diff, or log views) in another
  ;; window, keeping the Magit buffer visible.
  (define-key magit-mode-map (kbd "M-RET") #'magit-diff-visit-file-other-window)

  ;; Enable word-level / intra-line diff highlights for all visible hunks
  (setq magit-diff-refine-hunk 'all))

;; --- 11. EDIFF / MAGIT SIDE-BY-SIDE DIFF CONFIGURATION ---
;; Force Ediff to split windows side-by-side horizontally instead of stacked vertically
(setq ediff-split-window-function 'split-window-horizontally)
;; Keep the Ediff control panel inside the same frame instead of opening a separate mini-frame
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
;; Force magit-ediff-dwim ('e') to prefer 2-way side-by-side diffs over 3-way diffs
(setq magit-ediff-dwim-show-on-hunks t)

;; --- 12. WELCOME SCREEN / DASHBOARD CONFIGURATION ---
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)

  ;; Display Header Banner & Title
  (setq dashboard-banner-logo-title "Welcome to Emacs")
  (setq dashboard-startup-banner 'official)

  ;; Configure recent files and projects limits
  (setq dashboard-items '((recents  . 9)
                          (projects . 9)))

  ;; Formatting and shortcuts
  (setq dashboard-center-content t)
  (setq dashboard-show-shortcuts t)

  (setq dashboard-custom-header
        " [r] Reload Last Session   |   [e] Open init.el ")

  ;; Helper functions for custom actions
  (defun my/dashboard-reload-session ()
    "Restore the previous desktop session."
    (interactive)
    (if (fboundp 'desktop-read)
        (desktop-read)
      (message "Desktop mode is not enabled.")))

  (defun my/dashboard-open-init-el ()
    "Open user init.el file directly."
    (interactive)
    (find-file user-init-file))

  ;; Keybindings inside dashboard-mode
  (with-eval-after-load 'dashboard
    (define-key dashboard-mode-map (kbd "r") #'my/dashboard-reload-session)
    (define-key dashboard-mode-map (kbd "e") #'my/dashboard-open-init-el))

  ;; Feed recent files & enable session tracking
  (recentf-mode 1)
  (setq recentf-max-saved-items 25))

;; Save session automatically on exit
(desktop-save-mode 1)
(setq desktop-restore-eager 5)

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

;; je hebt 'upcase-region' niet meer laten disablen toen je het benaderde via M-x
(put 'upcase-region 'disabled nil)
