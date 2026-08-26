;;; init-dap.el --- DAP Mode configuration for .NET Debugging -*- lexical-binding: t; -*-

(require 'dap-mode)

(let ((netcoredbg-dir "C:/projects/netcoredbg/"))
  (add-to-list 'exec-path netcoredbg-dir)
  (setenv "PATH" (concat netcoredbg-dir ";" (getenv "PATH"))))

(require 'dap-netcore)

(use-package dap-mode
  :ensure t
  :commands (dap-debug dap-hydra)
  :bind (("<f5>"    . my/dotnet-build-and-debug)
         ("<f4>"    . dap-disconnect)
         ("<f10>"   . dap-next)
         ("<f11>"   . dap-step-in)
         ("C-c d b" . dap-breakpoint-toggle)
         ("C-c d c" . dap-continue)
         ("C-c d e" . dap-eval))
  :config
  (dap-ui-mode 1)
  (dap-ui-controls-mode 1)
  (dap-tooltip-mode 1)

  (dap-register-debug-template
   "<APP_NAME_HERE> - Launch netcoredbg"
   (list :type "coreclr"
         :request "launch"
         :mode "launch"
         :name "<APP_NAME_HERE> - Launch netcoredbg"
         :program "C:/Development/API/<APP_NAME_HERE>/bin/Debug/net8.0/<APP_NAME_HERE>.dll"
         :cwd "C:/Development/API/<APP_NAME_HERE>"
         :stopAtEntry :json-false
         :justMyCode :json-false
         :requireExactSource :json-false
         :suppressJITOptimizations t
         :enableStepFiltering :json-false
         :env '(("ASPNETCORE_ENVIRONMENT" . "Development")
                ("ASPNETCORE_URLS" . "https://localhost:44320")
                ("ASPNETCORE_CONTENTROOT" . "C:/Development/API/<APP_NAME_HERE>"))
         :symbolOptions (list :searchMicrosoftSymbolServer t
                               :searchNuGetOrgSymbolServer t
                               :moduleFilter (list :mode "loadAllButExcluded"
                                                    :excludedModules []))))

  (dap-register-debug-template
   "<APP_NAME_HERE> - Attach netcoredbg"
   (list :type "coreclr"
         :request "attach"
         :mode "attach"
         :name "<APP_NAME_HERE> - Attach netcoredbg")))

(defvar my/<APP_NAME_HERE>-dir "C:/Development/API/<APP_NAME_HERE>")

(defun my/dotnet-build-and-debug ()
  "Terminate any running session, build, then launch the debugger."
  (interactive)
  (when (dap--cur-session)
    (message "Terminating existing debug session...")
    (dap-disconnect (dap--cur-session)))
  (let* ((default-directory my/<APP_NAME_HERE>-dir)
         (buf (get-buffer-create "*dotnet-build*")))
    (with-current-buffer buf (erase-buffer))
    (message "Building project...")
    (let ((proc (start-process "dotnet-build" buf "dotnet" "build")))
      (set-process-sentinel
       proc
       (lambda (_proc event)
         (if (string-match-p "finished" event)
             (progn
               (message "Build successful! Starting debugger...")
               (dap-debug
                (copy-tree
                 (cdr (assoc "<APP_NAME_HERE> - Launch netcoredbg"
                             dap-debug-template-configurations)))))
           (progn
             (message "Build FAILED. Debugger aborted.")
             (display-buffer buf))))))))

(provide 'init-dap)