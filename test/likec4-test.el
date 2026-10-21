;;; likec4-test.el --- Tests for likec4 -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'likec4)

(ert-deftest likec4-auto-mode ()
  (dolist (file '("a.c4" "a.likec4" "a.like-c4"))
    (with-temp-buffer
      (setq buffer-file-name file)
      (set-auto-mode)
      (should (eq major-mode 'likec4-mode)))))

(ert-deftest likec4-indent-and-comments ()
  (with-temp-buffer
    (likec4-mode)
    (insert "model {\nfoo = component 'x // y' {\n// note\n}\n}\n")
    (indent-region (point-min) (point-max))
    (should (equal (buffer-string)
                   "model {\n  foo = component 'x // y' {\n    // note\n  }\n}\n"))
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "note")
    (should (nth 4 (syntax-ppss)))
    (goto-char (point-min))
    (search-forward "y'")
    (should-not (nth 4 (syntax-ppss)))
    (should (eq (get-text-property (point-min) 'face) 'font-lock-keyword-face))))

(ert-deftest likec4-eglot-registration ()
  (skip-unless (require 'eglot nil t))
  (let* ((likec4-server-install-dir (make-temp-file "likec4" t))
         (bin (expand-file-name "node_modules/.bin" likec4-server-install-dir))
         (exe (expand-file-name "likec4" bin))
         (contact (cdr (assq 'likec4-mode eglot-server-programs))))
    (should contact)
    (make-directory bin t)
    (write-region "" nil exe)
    (set-file-modes exe #o755)
    (should (equal (funcall contact nil) (list exe "lsp" "--stdio")))
    (let ((likec4-lsp-command '("x")))
      (should (equal (funcall contact nil) '("x"))))
    (delete-directory likec4-server-install-dir t)))

;;; likec4-test.el ends here
