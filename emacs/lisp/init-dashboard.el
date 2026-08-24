;;; init-dashboard.el --- Welcome Screen & Sessions -*- lexical-binding: t; -*-

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)

  (setq dashboard-banner-logo-title "Welcome to Emacs")
  (setq dashboard-startup-banner 'official)

  (setq dashboard-items '((recents  . 9)
                          (projects . 9)))

  (setq dashboard-center-content t)
  (setq dashboard-show-shortcuts t)

  (setq dashboard-custom-header
        " [r] Reload Last Session   |   [e] Open init.el ")

  (defun my/dashboard-reload-session ()
    (interactive)
    (if (fboundp 'desktop-read)
        (desktop-read)
      (message "Desktop mode is not enabled.")))

  (defun my/dashboard-open-init-el ()
    (interactive)
    (find-file user-init-file))

  (with-eval-after-load 'dashboard
    (define-key dashboard-mode-map (kbd "r") #'my/dashboard-reload-session)
    (define-key dashboard-mode-map (kbd "e") #'my/dashboard-open-init-el))

  (recentf-mode 1)
  (setq recentf-max-saved-items 25))

(desktop-save-mode 1)
(setq desktop-restore-eager 5)

(provide 'init-dashboard)