;;; init-latex.el --- AUCTeX & PDF Tools Setup -*- lexical-binding: t; -*-

(if (eq system-type 'windows-nt)
    ;; Windows: Use built-in DocView mode
    (use-package tex
      :ensure auctex
      :config
      (setq TeX-PDF-mode t)
      (setq TeX-source-correlate-mode t)
      (setq TeX-source-correlate-method 'synctex)
      (setq TeX-parse-self t)
      (setq TeX-auto-save t)
      (setq TeX-view-program-selection '((output-pdf "DocView"))))

  ;; Linux/Debian: Use pdf-tools
  (use-package pdf-tools
    :ensure t
    :config
    (pdf-tools-install)
    (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

  (use-package tex
    :ensure auctex
    :config
    (setq TeX-PDF-mode t)
    (setq TeX-source-correlate-mode t)
    (setq TeX-source-correlate-method 'synctex)
    (setq TeX-source-correlate-start-server t)
    (setq TeX-parse-self t)
    (setq TeX-auto-save t)
    (setq TeX-view-program-selection '((output-pdf "PDF Tools")))))

(defun my/latex-keybindings ()
  "Custom keybindings for LaTeX editing buffers."
  (local-set-key (kbd "C-c C-v") #'TeX-view))

(add-hook 'LaTeX-mode-hook #'my/latex-keybindings)
(add-hook 'latex-mode-hook #'my/latex-keybindings)
(add-hook 'plain-TeX-mode-hook #'my/latex-keybindings)

(provide 'init-latex)