;;; init-editing.el --- HTML, Emmet, Smartparens & File Backups -*- lexical-binding: t; -*-

;; --- HTML MATCHING TAG HIGHLIGHT ---
(defface my/matching-tag-face
  '((t :inherit highlight :weight bold))
  "Face used to highlight matching opening/closing HTML tag names.")

(defvar-local my/tag-match-overlays nil)

(defun my/tag-match--clear ()
  (mapc #'delete-overlay my/tag-match-overlays)
  (setq my/tag-match-overlays nil))

(defun my/tag-match--node-by-type (node type)
  (and node
       (seq-find (lambda (c) (equal (treesit-node-type c) type))
                 (treesit-node-children node))))

(defun my/tag-match--highlight-node (node)
  (when node
    (let ((ov (make-overlay (treesit-node-start node) (treesit-node-end node))))
      (overlay-put ov 'face 'my/matching-tag-face)
      (push ov my/tag-match-overlays))))

(defun my/highlight-matching-tag ()
  (my/tag-match--clear)
  (when (and (derived-mode-p 'html-ts-mode)
             (treesit-parser-list))
    (let* ((node (treesit-node-at (point)))
           (tag-node (and node
                          (treesit-parent-until
                           node
                           (lambda (n) (member (treesit-node-type n)
                                               '("start_tag" "end_tag")))
                           t)))
           (element (and tag-node (treesit-node-parent tag-node))))
      (when (and element (equal (treesit-node-type element) "element"))
        (let ((start-tag (my/tag-match--node-by-type element "start_tag"))
              (end-tag (my/tag-match--node-by-type element "end_tag")))
          (my/tag-match--highlight-node
           (my/tag-match--node-by-type start-tag "tag_name"))
          (my/tag-match--highlight-node
           (my/tag-match--node-by-type end-tag "tag_name")))))))

(define-minor-mode my/highlight-matching-tag-mode
  "Highlight the matching opening/closing HTML tag pair around point."
  :lighter nil
  (if my/highlight-matching-tag-mode
      (add-hook 'post-command-hook #'my/highlight-matching-tag nil t)
    (remove-hook 'post-command-hook #'my/highlight-matching-tag t)
    (my/tag-match--clear)))

(add-hook 'html-ts-mode-hook #'my/highlight-matching-tag-mode)

;; --- EMMET MODE ---
(use-package emmet-mode
  :hook ((html-mode . emmet-mode)
         (html-ts-mode . emmet-mode)
         (mhtml-mode . emmet-mode)
         (web-mode . emmet-mode)
         (tsx-ts-mode . emmet-mode))
  :config
  (setq emmet-move-cursor-after-expanding t
        emmet-self-closing-tag-style "html")

  (defun my/emmet-tab-or-indent ()
    "Expand Emmet abbreviation at point if there is one, otherwise indent."
    (interactive)
    (if (and (bound-and-true-p emmet-mode)
             (emmet-expr-on-line))
        (emmet-expand-line nil)
      (my/tab-or-indent-more)))

  (define-key emmet-mode-keymap (kbd "TAB") #'my/emmet-tab-or-indent)
  (define-key emmet-mode-keymap (kbd "<tab>") #'my/emmet-tab-or-indent))

;; --- SMARTPARENS ---
(use-package smartparens
  :hook ((html-mode . smartparens-mode)
         (html-ts-mode . smartparens-mode)
         (mhtml-mode . smartparens-mode)
         (web-mode . smartparens-mode)
         (tsx-ts-mode . smartparens-mode))
  :config
  (require 'smartparens-html)
  (dolist (mode '(LaTeX-mode latex-mode plain-TeX-mode))
    (add-to-list 'sp-ignore-modes-list mode))
  (smartparens-global-mode t)
  (sp-with-modes '(html-mode html-ts-mode mhtml-mode web-mode tsx-ts-mode)
    (sp-local-pair "<" ">" :actions '(insert wrap))
    (sp-local-pair "{{" "}}" :post-handlers '("| "))
    (sp-local-pair "{" "}" :unless '(sp-in-string-p))))


;; Redirect backup (file~) and auto-save (#file#) files to central directories

(let ((backup-dir (expand-file-name "backups/" user-emacs-directory))
      (auto-save-dir (expand-file-name "auto-saves/" user-emacs-directory)))

  ;; Create directories automatically if they don't exist
  (unless (file-exists-p backup-dir)
    (make-directory backup-dir t))
  (unless (file-exists-p auto-save-dir)
    (make-directory auto-save-dir t))

  ;; Configure backup files (file~)
  (setq backup-directory-alist `(("." . ,backup-dir))
        make-backup-files t
        vc-make-backup-files t
        backup-by-copying t)

  ;; Configure auto-save files (#file#)
  (setq auto-save-file-name-transforms `((".*" ,auto-save-dir t))))

;; Disable lockfiles (.#filename) to prevent Windows file-unlocking warnings
(setq create-lockfiles nil)

;; --- INSTANT AUTO-SAVE (debounced, saves the real file) ---
;; Saves the actual visited file after `auto-save-visited-interval` (of 300) milliseconds
;; of idle time, instead of writing to disk on every single keystroke.
(setq auto-save-visited-interval 0.3)
(auto-save-visited-mode 1)

(provide 'init-editing)