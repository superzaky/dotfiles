;;; init-ui.el --- Visuals, Indentation & Theme -*- lexical-binding: t; -*-

(global-display-line-numbers-mode t)
(setq ring-bell-function 'ignore)

;; Set Maple Mono as default font
(set-face-attribute 'default nil
                    :font "Maple Mono"
                    :height 120
                    :weight 'regular)

;; Ensure fixed-pitch face (used in org tables, code blocks) matches
(set-face-attribute 'fixed-pitch nil
                    :font "Maple Mono"
                    :height 120)

;; Lock cursor to vertical center
(setq scroll-preserve-screen-position t
      scroll-conservatively 0
      scroll-margin 9999)

(delete-selection-mode 1)

;; --- EF THEMES & MODUS INTEGRATION ---
(require 'ef-themes)

;; Make Modus commands (rotate, select, random) control Ef themes
(ef-themes-take-over-modus-themes-mode 1)

;; Theme customizations
(setq modus-themes-mixed-fonts t)
(setq modus-themes-italic-constructs t)

;; Keybindings to quickly preview themes:
;; <f5>    -> Rotate/cycle to the next Ef theme
;; C-<f5>  -> Interactive selection list with completion
;; M-<f5>  -> Load a completely random Ef theme
(global-set-key (kbd "<f6>") #'modus-themes-rotate)
(global-set-key (kbd "C-<f6>") #'modus-themes-select)
(global-set-key (kbd "M-<f6>") #'modus-themes-load-random)

;; Load starting theme
(modus-themes-load-theme 'ef-autumn)

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