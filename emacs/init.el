(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; --- 1. AUTOMATIC PACKAGE INSTALLATION ---
(dolist (pkg '(vertico orderless corfu marginalia cape dape magit eldoc-box auctex scss-mode haskell-mode))
  (unless (package-installed-p pkg)
    (package-refresh-contents)
    (package-install pkg)))

;; --- 2. LINE NUMBERS & VISUALS ---
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq ring-bell-function 'ignore)

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

;; --- 6. FUZZY SEARCH ---
(vertico-mode 1)
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))
(marginalia-mode 1)

;; --- 7. WINDOW NAVIGATION ---
(use-package windmove
  :ensure nil
  :config
  (windmove-default-keybindings 'meta))

;; --- 8. DEBUGGER CONFIGURATION (Dape) ---
(use-package dape
  :ensure nil
  :bind (("C-c d d" . dape)                   ; Safe custom prefix to avoid Dired conflicts
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
                  :ghciEnv ,(make-hash-table)             ; FIXED: Evaluates to an empty JSON object {}
                  :internalConsoleOptions "neverOpen")))

;; --- 9. GLOBAL KEYBINDINGS ---
(global-set-key (kbd "C-c r")   'restart-emacs)
(global-set-key (kbd "C-x g")   'magit-status)

(custom-set-variables
 '(package-selected-packages '(dape vertico orderless corfu marginalia cape magit eldoc-box auctex scss-mode haskell-mode)))
(custom-set-faces)