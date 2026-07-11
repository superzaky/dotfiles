(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install required packages automatically
(dolist (pkg '(vertico orderless corfu marginalia cape dape))
  (unless (package-installed-p pkg)
    (package-refresh-contents)
    (package-install pkg)))

;; --- 1. LINE NUMBERS & RELATIVE LOOKUPS ---
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)

;; --- 2. SILENCE SYSTEM BELLS ---
(setq ring-bell-function 'ignore)

;; --- 3. THE IDE ENGINE (Eglot for Python) ---
(add-hook 'python-mode-hook 'eglot-ensure)
(add-hook 'python-ts-mode-hook 'eglot-ensure)

;; --- 4. AUTOCOMPLETE & DOCUMENTATION POPUPS ---
(use-package corfu
  :init
  (global-corfu-mode)
  :config
  (setq corfu-auto t                 ; Complete automatically as you type
        corfu-auto-delay 0.1         ; Snappy popups
        corfu-auto-prefix 2          ; Complete after 2 characters
        corfu-popupinfo-mode t))     ; Show docs next to selection

;; --- 5. FUZZY SEARCH (Files & Text menus) ---
(vertico-mode 1)
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(marginalia-mode 1)

;; --- 6. WINDOW NAVIGATION (Alt + Arrow Keys) ---
(use-package windmove
  :ensure nil
  :config
  (windmove-default-keybindings 'meta))

;; --- 7. DEBUGGER ENGINE (Dape Setup) ---
(with-eval-after-load 'dape
  (setq dape-buffer-window-arrangement 'gdb)
  ;; IMPORTANT: Force Dape to find the default python executable in your environment.
  ;; This ensures Dape can invoke python -m debugpy.adapter automatically.
  (add-to-list 'dape-configs
               `(debugpy
                 modes (python-mode python-ts-mode)
                 command "python3"
                 command-args ("-m" "debugpy.adapter")
                 :type "executable"
                 :request "launch"
                 :program dape-buffer-default)))

;; --- 8. GLOBAL SHORTCUT KEYS ---
(global-set-key (kbd "C-c d d") 'dape)
(global-set-key (kbd "C-c d b") 'dape-breakpoint-toggle)
(global-set-key (kbd "C-c r")   'restart-emacs)

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
