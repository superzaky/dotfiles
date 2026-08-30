;;; init-lsp.el --- Tree-Sitter, LSP Engine & Autocomplete -*- lexical-binding: t; -*-

;; --- TREE-SITTER ---
(setq major-mode-remap-alist
      '((typescript-mode . typescript-ts-mode)
        (tsx-mode        . tsx-ts-mode)
        (js-mode          . js-ts-mode)
        (javascript-mode . js-ts-mode)
        (python-mode     . python-ts-mode)
        (csharp-mode     . csharp-ts-mode)
        (css-mode        . css-ts-mode)
        (html-mode       . html-ts-mode)))

(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.html\\'" . html-ts-mode))

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

;; --- HOVER HELP ---
(global-set-key (kbd "C-c h") #'eldoc-box-help-at-point)
(global-set-key (kbd "C-c q") #'eldoc-box-quit-frame)

;; --- LSP MODE ---
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((python-mode python-ts-mode csharp-mode csharp-ts-mode
          typescript-mode typescript-ts-mode tsx-mode tsx-ts-mode
          js-mode js-ts-mode js2-mode html-mode html-ts-mode
          mhtml-mode css-mode css-ts-mode scss-mode
          LaTeX-mode latex-mode) . lsp-deferred)
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-disabled-clients '(html-ls))
  (add-to-list 'lsp-language-id-configuration '(LaTeX-mode . "latex"))
  (add-to-list 'lsp-language-id-configuration '(latex-mode . "latex"))

  (when (eq system-type 'windows-nt)
    (setq lsp-clients-typescript-server "typescript-language-server")
    (setq lsp-clients-typescript-command '("typescript-language-server.cmd" "--stdio")))

  (setq lsp-clients-typescript-init-opts '(:importModuleSpecifierPreference "relative"))
  (setq lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-modeline-workspace-status-enable nil)

  (setq lsp-idle-delay 0.2
        lsp-log-io nil
        lsp-completion-provider :capf
        lsp-completion-filter-on-kind nil
        lsp-enable-on-type-formatting nil
        lsp-enable-indentation nil
        lsp-enable-snippet t
        lsp-completion-additional-text-edit t
        lsp-completion-show-detail t
        lsp-completion-show-kind t
        lsp-enable-symbol-highlighting t
        lsp-completion-no-auto-import nil
        lsp-response-timeout 10)

  (advice-add 'lsp--on-idle :around
              (lambda (orig-fun &rest args)
                (when (and (bound-and-true-p lsp-mode)
                           (lsp-workspaces))
                  (ignore-errors (apply orig-fun args)))))

  (defun my/lsp-mode-setup-completion ()
    (setq-local completion-category-defaults nil)
    (setq-local completion-styles '(orderless flex basic)))
  (add-hook 'lsp-mode-hook #'my/lsp-mode-setup-completion))

;; that runs before you open your first .cs file this session:
(with-eval-after-load 'csharp-mode
  (defun csharp-ts-mode--test-typeof-expression ()
    "Return non-nil only if the exact (typeof_expression (identifier))
pattern csharp-ts-mode uses is structurally valid for the installed
grammar — not just that the node type exists (upstream bug workaround)."
    (treesit-query-valid-p 'c-sharp "(typeof_expression (identifier))")))

;; TSServer Shim Workaround
(defun my/lsp-ensure-tsserver-shim ()
  (let* ((ts-dir (expand-file-name "npm/typescript" lsp-server-install-dir))
         (bin-dir (expand-file-name "bin" ts-dir))
         (shim (expand-file-name "tsserver" bin-dir))
         (target (expand-file-name "lib/node_modules/typescript/lib/tsserver.js" ts-dir)))
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
  (advice-add 'lsp--npm-dependency-path :around #'my/lsp--npm-dependency-path-advice))

(use-package lsp-ui
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-delay 0.2
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-show-hover nil))

(use-package lsp-haskell
  :hook (haskell-mode . lsp-deferred))

;; --- ANGULAR LSP ---
(use-package lsp-angular
  :ensure nil
  :hook ((typescript-mode typescript-ts-mode html-mode html-ts-mode mhtml-mode) . lsp-deferred)
  :config
  (defun my/lsp-angular-get-probe-locations ()
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

;; --- CORFU & CAPE ---
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
  (define-key corfu-map (kbd "C-<tab>") #'corfu-insert)
  (define-key corfu-map (kbd "RET") #'corfu-insert))

(use-package cape
  :init
  (defun my/setup-lsp-capf-super ()
    (setq-local completion-at-point-functions
                (list #'lsp-completion-at-point
                      #'cape-dabbrev
                      #'cape-keyword)))
  (setq cape-dabbrev-check-other-buffers t)
  (add-hook 'lsp-mode-hook #'my/setup-lsp-capf-super 90))

(provide 'init-lsp)
