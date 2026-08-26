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

;; je hebt 'upcase-region' niet meer laten disablen toen je het benaderde via M-x
(put 'upcase-region 'disabled nil)
