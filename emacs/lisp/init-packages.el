;;; init-packages.el --- Package Manager Setup -*- lexical-binding: t; -*-

(require 'package)

(setq package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(vertico orderless corfu marginalia cape dape magit eldoc-box auctex
                       scss-mode haskell-mode consult wgrep lsp-mode lsp-ui lsp-haskell
                       smartparens emmet-mode dashboard diff-hl))
  (unless (package-installed-p pkg)
    (condition-case nil
        (package-install pkg)
      (error
       (package-refresh-contents)
       (package-install pkg)))))

(provide 'init-packages)