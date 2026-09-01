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
  (org-roam-directory (file-truename "~/org-roam")) ; Default root path for notes
  ;; Remove the timestamp prefix from created filenames:
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)))
  :bind (("C-c n f" . org-roam-node-find)          ; Find or create a note in default dir
         ("C-c n c" . my/org-roam-node-find-in-current-dir) ; Find or create in CURRENT dir
         ("C-c n i" . org-roam-node-insert)        ; Insert a link to another note at point
         ("C-c n l" . org-roam-buffer-toggle))     ; Toggle sidebar showing backlinks
  :config
  (defun my/org-roam-node-find-in-current-dir ()
    "Create or find an Org-roam node in the current buffer's directory."
    (interactive)
    (let ((org-roam-directory (file-name-directory (or (buffer-file-name) default-directory))))
      (org-roam-node-find)))

  (org-roam-db-autosync-mode))

(provide 'init-org)