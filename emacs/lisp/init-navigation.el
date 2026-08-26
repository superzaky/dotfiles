;;; init-navigation.el --- Fuzzy Search, Dired & Window Management -*- lexical-binding: t; -*-

;; --- VERTICO & CONSULT ---
(vertico-mode 1)

(use-package orderless
  :init
  (setq completion-styles '(orderless flex basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion))
                                        (lsp-capf (styles basic orderless)))))

(marginalia-mode 1)

(use-package consult
  :bind (("C-c f g" . consult-ripgrep)
         ("C-c s r" . consult-ripgrep)
         ("C-s"     . consult-line)
         ("C-c f f" . consult-fd)
         ("C-x b"   . consult-buffer)))

(use-package wgrep
  :config
  (setq wgrep-auto-save-buffer t))

;; --- DIRED ---
(use-package dired
  :ensure nil
  :config
  (require 'dired-x)
  (setq dired-kill-when-opening-new-dired-buffer t)
  :bind (("C-x C-j" . dired-jump)))

;; --- WINDMOVE & WINDOW MANAGEMENT ---
(use-package windmove
  :ensure nil
  :config
  (windmove-default-keybindings 'meta)
  (define-prefix-command 'mijn-venster-map)
  (global-set-key (kbd "M-m") 'mijn-venster-map)

  (define-key mijn-venster-map (kbd "v") 'split-window-right)
  (define-key mijn-venster-map (kbd "s") 'split-window-below)
  (define-key mijn-venster-map (kbd "x") 'delete-window)
  (define-key mijn-venster-map (kbd "o") 'delete-other-windows)

  (define-key mijn-venster-map (kbd "p p") 'project-switch-project)
  (define-key mijn-venster-map (kbd "p f") 'project-find-file)
  (define-key mijn-venster-map (kbd "p s") 'project-shell))

;; --- HELPER COMMANDS ---
(defun my/copy-current-file-name (&optional arg)
  "Copy current filename or full path with C-u."
  (interactive "P")
  (if-let ((path (buffer-file-name)))
      (let ((result (if arg path (file-name-nondirectory path))))
        (kill-new result)
        (message "Copied %s to clipboard: %s"
                 (if arg "full path" "filename")
                 result))
    (user-error "Current buffer is not visiting a file")))

(global-set-key (kbd "C-c f c") #'my/copy-current-file-name)

(defun copy-line-or-region ()
  "Copy current line if no active region."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (kill-ring-save (line-beginning-position) (line-beginning-position 2))
    (message "Copied line")))

(global-set-key (kbd "M-w") 'copy-line-or-region)

;; --- KILL ALL BUFFERS SHORTCUT ---
(defun my/kill-all-buffers ()
  "Kill all user buffers, preserving system buffers and leaving an open *scratch* buffer."
  (interactive)
  (when (yes-or-no-p "Are you sure you want to kill all open buffers? ")
    (dolist (buf (buffer-list))
      (let ((name (buffer-name buf)))
        ;; Don't kill internal buffers like *Messages* or hidden buffers starting with space
        (unless (or (string-prefix-p "*" name)
                    (string-prefix-p " " name))
          (kill-buffer buf))))
    (switch-to-buffer "*scratch*")))

;; Bind to your preferred key combination (e.g., C-c b k)
(global-set-key (kbd "C-c b k") #'my/kill-all-buffers)

(provide 'init-navigation)
