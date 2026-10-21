;;; funcs.el --- likec4 layer functions file for Spacemacs -*- lexical-binding: t; -*-

;;; Code:

(defun spacemacs//likec4-setup-backend ()
  "Start the language server selected by `likec4-backend'."
  (pcase likec4-backend
    ('lsp (lsp-deferred))
    ('eglot (eglot-ensure))))

;;; funcs.el ends here
