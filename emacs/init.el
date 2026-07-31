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

(dolist (pkg '(vertico orderless corfu marginalia cape dape magit eldoc-box auctex scss-mode haskell-mode consult wgrep))
  (unless (package-installed-p pkg)
    (package-install pkg)))

;; --- 2. LINE NUMBERS & VISUALS (Theme Configuration) ---
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq ring-bell-function 'ignore)

;; Load Modus Vivendi (Built-in Accessible Dark Theme)
(load-theme 'modus-vivendi t)

;; --- 3. MANUAL HOVER DOCUMENTATION ---
;; Press C-c h to display documentation popup manually at point
;; Press C-c q to close the popup frame
(global-set-key (kbd "C-c h") #'eldoc-box-help-at-point)
(global-set-key (kbd "C-c q") #'eldoc-box-quit-frame)

;; --- 4. THE IDE ENGINE (Eglot Multi-Language Hooks) ---
(dolist (hook '(python-mode-hook python-ts-mode-hook
                haskell-mode-hook
                csharp-mode-hook
                typescript-mode-hook tsx-mode-hook js-mode-hook js2-mode-hook
                html-mode-hook css-mode-hook scss-mode-hook))
  (add-hook hook 'eglot-ensure))

;; --- 5. AUTOCOMPLETE & POPUPS ---
(use-package corfu
  :init
  (global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2
        corfu-popupinfo-mode t))     ; Required: Shows method/function docs inside the completion menu

;; --- 6. FUZZY SEARCH & TELESCOPE EQUIVALENTS ---
(vertico-mode 1)
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
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

;; --- 7. WINDOW NAVIGATION ---
(use-package windmove
  :ensure nil
  :config
  (windmove-default-keybindings 'meta))

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
