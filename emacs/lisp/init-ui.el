;;; init-ui.el --- Visuals, Indentation & Theme -*- lexical-binding: t; -*-

(global-display-line-numbers-mode t)
(setq ring-bell-function 'ignore)

;; Lock cursor to vertical center
(setq scroll-preserve-screen-position t
      scroll-conservatively 0
      scroll-margin 9999)

(delete-selection-mode 1)
(load-theme 'modus-vivendi t)

;; Indentation: Spaces instead of Tabs
(setq-default indent-tabs-mode nil)
(setq-default typescript-ts-mode-indent-offset 2
              js-indent-level 2
              css-indent-offset 2
              sgml-basic-offset 2
              web-mode-markup-indent-offset 2
              haskell-indent-offset 2)

;; VS Code-style TAB / Shift-TAB
(defun my/tab-or-indent-more ()
  "Indent line or keep indenting further on repeated calls."
  (interactive)
  (if (memq last-command '(my/tab-or-indent-more my/emmet-tab-or-indent))
      (indent-line-to (+ (current-indentation) tab-width))
    (let ((prev-indent (current-indentation)))
      (indent-for-tab-command)
      (when (= prev-indent (current-indentation))
        (indent-line-to (+ prev-indent tab-width))))))

(defun my/backtab-unindent ()
  "Un-indent the current line by one step."
  (interactive)
  (indent-line-to (max 0 (- (current-indentation) tab-width))))

(global-set-key (kbd "TAB") #'my/tab-or-indent-more)
(global-set-key (kbd "<backtab>") #'my/backtab-unindent)

(provide 'init-ui)