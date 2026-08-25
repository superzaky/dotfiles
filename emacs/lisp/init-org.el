;;; init-org.el --- Org Mode & Org-Roam Configuration -*- lexical-binding: t; -*-

(use-package org
  :ensure nil ; Built-in to Emacs, do not download from ELPA/MELPA
  :defer t
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         :map org-mode-map
         ("M-m h" . org-metaleft)  ; Promote heading level
         ("M-m l" . org-metaright) ; Demote heading level
         ("M-m k" . org-metaup)    ; Move heading up
         ("M-m j" . org-metadown)) ; Move heading down
  :config
  ;; Enable visual line wrapping for readable notes
  (add-hook 'org-mode-hook #'visual-line-mode)

  ;; Modern indent mode for structured headings
  (add-hook 'org-mode-hook #'org-indent-mode)
  (setq org-log-done 'time
        org-hide-emphasis-markers t
        org-ellipsis " ▾"))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/org-roam")) ; Path to your note collection
  :bind (("C-c n f" . org-roam-node-find)   ; Find or create a note
         ("C-c n i" . org-roam-node-insert) ; Insert a link to another note at point
         ("C-c n l" . org-roam-buffer-toggle)) ; Toggle sidebar showing backlinks
  :config
  (org-roam-db-autosync-mode))

(provide 'init-org)
