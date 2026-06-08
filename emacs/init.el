(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install Dape if not already installed
(unless (package-installed-p 'dape)
  (package-refresh-contents)
  (package-install 'dape))

;; Optimizations for debugging display
(with-eval-after-load 'dape
  (setq dape-buffer-window-arrangement 'gdb))