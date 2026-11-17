;;; init.el --- Main Emacs Configuration Entry Point -*- lexical-binding: t; -*-

;; Add modular configuration directory to load-path
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Load configuration modules
(require 'init-packages)
(require 'init-ui)
(require 'init-lsp)
(require 'init-latex)
(require 'init-editing)
(require 'init-navigation)
(require 'init-tools)
(require 'init-dashboard)
(require 'init-org)
(require 'init-dap)

;; Custom system settings (managed automatically by Emacs)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; Force disable menu-bar and tool-bar after custom.el and all modules load
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Also set frame parameters for any new frames/windows you open
(add-to-list 'default-frame-alist '(menu-bar-lines . 0))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))
(add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))

;; je hebt 'upcase-region' niet meer laten disablen toen je het benaderde via M-x
(put 'upcase-region 'disabled nil)
