(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Fast window navigation using Modifier + Arrow keys
(use-package windmove
  :ensure nil ; Built-in, no installation required
  :config
  ;; Option A: Hold Meta (Alt) + Arrow keys to jump windows
  (windmove-default-keybindings 'meta))

;; turn off sound, for example, when there are no buffers to switch upon to the utmost right
(setq ring-bell-function 'ignore)

;; Install Dape if not already installed
(unless (package-installed-p 'dape)
  (package-refresh-contents)
  (package-install 'dape))

;; Configuration for Dape
(with-eval-after-load 'dape
  ;; Use 'gdb layout for debugging windows
  (setq dape-buffer-window-arrangement 'gdb)
  
  ;; IMPORTANT: Force Dape to find the default python executable in your environment.
  ;; This ensures Dape can invoke python -m debugpy.adapter automatically.
  (add-to-list 'dape-configs
               `(debugpy
                 modes (python-mode python-ts-mode)
                 command "python3"  ; Change to "python3" if on Mac/Linux and "python" doesn't work
                 command-args ("-m" "debugpy.adapter")
                 :type "executable"
                 :request "launch"
                 :program dape-buffer-default)))

;; Quick shortcut to start/interact with the debugger
(global-set-key (kbd "C-c d d") 'dape)
(global-set-key (kbd "C-c d b") 'dape-breakpoint-toggle)

(custom-set-variables
 '(package-selected-packages '(dape)))
(custom-set-faces)
