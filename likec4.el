;;; likec4.el --- Major mode and LSP integration for LikeC4 -*- lexical-binding: t; -*-

;; Copyright (C) 2026 drlkf

;; Author: drlkf
;; URL: https://github.com/drlkf/likec4.el
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for LikeC4 (https://likec4.dev) files, with registration
;; of the LikeC4 language server (`likec4 lsp --stdio') for both Eglot
;; and lsp-mode.  Start the server with `eglot-ensure' or `lsp' from
;; `likec4-mode-hook'.

;;; Code:

(defgroup likec4 nil
  "Support for LikeC4 architecture-as-code files."
  :group 'languages
  :link '(url-link "https://likec4.dev"))

(defcustom likec4-lsp-command nil
  "Command and arguments used to start the LikeC4 language server.
When nil, run the npm-managed server from `likec4-server-install-dir',
installing it with `likec4-install-server' if missing."
  :type '(choice (const :tag "npm-managed" nil) (repeat string)))

(defcustom likec4-server-install-dir (locate-user-emacs-file "likec4-server/")
  "Directory where `likec4-install-server' installs the npm package."
  :type 'directory)

(defcustom likec4-server-npm-package "likec4@latest"
  "Package spec installed from npm by `likec4-install-server', e.g. likec4@1.40.0."
  :type 'string)

(defun likec4--server-executable ()
  "Return the npm-managed LikeC4 executable, or nil if not installed."
  (locate-file "likec4"
               (list (expand-file-name "node_modules/.bin" likec4-server-install-dir))
               exec-suffixes #'file-executable-p))

(defun likec4--lsp-command ()
  "Return the LikeC4 language server command, or nil if unavailable."
  (or likec4-lsp-command
      (when-let* ((exe (likec4--server-executable)))
        (list exe "lsp" "--stdio"))))

;;;###autoload
(defun likec4-install-server ()
  "Install or update the LikeC4 language server from npm."
  (interactive)
  (let ((npm (or (executable-find "npm") (user-error "Cannot find npm")))
        (dir (expand-file-name likec4-server-install-dir)))
    (make-directory dir t)
    (message "Installing %s into %s..." likec4-server-npm-package dir)
    ;; ponytail: synchronous, blocks Emacs during install; go async if it bothers anyone
    (unless (zerop (call-process npm nil "*likec4-install*" nil
                                 "install" "--prefix" dir likec4-server-npm-package))
      (error "Installing %s failed, see *likec4-install*" likec4-server-npm-package))
    (message "Installed %s" likec4-server-npm-package)))

(defcustom likec4-indent-offset 2
  "Indentation offset for `likec4-mode'."
  :type 'integer
  :safe #'integerp)

(defconst likec4--keywords
  '("alt" "and" "as" "autoLayout" "border" "break" "catch" "crow" "dashed"
    "deployment" "deploymentNode" "diamond" "dot" "dotted" "dynamic" "else"
    "element" "exclude" "extend" "extends" "finally" "from" "global" "group"
    "head" "icons" "if" "import" "include" "includeAncestors" "instance"
    "instanceOf" "is" "it" "kind" "likec4lib" "line" "loop" "metadata"
    "model" "node" "none" "normal" "not" "odiamond" "odot" "of" "onormal"
    "open" "opt" "or" "order" "par" "parallel" "predicate" "predicateGroup"
    "rank" "relationship" "routing" "shape" "solid" "source" "specification"
    "style" "styleGroup" "tag" "tail" "target" "this" "try" "vee" "view"
    "views" "when" "where" "with"
    "rectangle" "component" "person" "browser" "mobile" "cylinder" "storage"
    "queue" "bucket" "document" "agent"))

(defconst likec4--properties
  '("title" "color" "description" "technology" "navigateTo" "notation"
    "multiple" "size" "padding" "textSize" "opacity" "variant" "iconColor"
    "iconPosition" "iconSize" "sizing" "link" "icon"))

(defconst likec4--constants
  '("true" "false" "TopBottom" "LeftRight" "BottomTop" "RightLeft"
    "xsmall" "xs" "small" "sm" "medium" "md" "large" "lg" "xl" "xlarge"
    "diagram" "sequence" "spline" "ortho" "same" "min" "max" "sink"
    "amber" "blue" "gray" "green" "indigo" "muted" "primary" "secondary"
    "red" "sky" "slate"))

(defconst likec4--font-lock-keywords
  `(("-\\[[^]\n]*\\]->\\|<->\\|<-\\|->" . font-lock-function-name-face)
    ("#[[:xdigit:]]\\{3,8\\}\\_>" . font-lock-constant-face)
    ("#[[:alnum:]_-]+" . font-lock-type-face)
    (,(regexp-opt likec4--properties 'symbols) . font-lock-variable-name-face)
    (,(regexp-opt likec4--keywords 'symbols) . font-lock-keyword-face)
    (,(regexp-opt likec4--constants 'symbols) . font-lock-constant-face)
    ("\\_<\\(?:rgba?\\)\\_>" . font-lock-builtin-face)
    ("\\_<[[:digit:]]+\\(?:\\.[[:digit:]]+\\|%\\)?\\_>" . font-lock-constant-face)))

(defvar likec4-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?_ "_" table)
    table)
  "Syntax table for `likec4-mode'.")

(defun likec4-indent-line ()
  "Indent current line by brace depth."
  (let* ((ppss (save-excursion (syntax-ppss (line-beginning-position))))
         (depth (save-excursion
                  (back-to-indentation)
                  (- (car (syntax-ppss))
                     (if (looking-at-p "[]})]") 1 0))))
         (column (* (max depth 0) likec4-indent-offset)))
    (unless (nth 3 ppss)
      (if (<= (current-column) (current-indentation))
          (indent-line-to column)
        (save-excursion (indent-line-to column))))))

;;;###autoload
(define-derived-mode likec4-mode prog-mode "LikeC4"
  "Major mode for LikeC4 architecture-as-code files."
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "\\(?://+\\|/\\*+\\)\\s-*")
  (setq-local font-lock-defaults '(likec4--font-lock-keywords))
  (setq-local indent-line-function #'likec4-indent-line)
  ;; Eglot sends `tab-width' as the LSP formatting tabSize
  (setq-local tab-width likec4-indent-offset)
  (setq-local indent-tabs-mode nil)
  (setq-local electric-indent-chars (append "{}()" electric-indent-chars)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(?:c4\\|likec4\\|like-c4\\)\\'" . likec4-mode))

(defun likec4--eglot-contact (&optional _interactive)
  "Return the Eglot contact for the LikeC4 language server."
  (or (likec4--lsp-command)
      (and (y-or-n-p "LikeC4 language server not installed, install it from npm? ")
           (progn (likec4-install-server) (likec4--lsp-command)))
      (user-error "LikeC4 language server not available, see `likec4-install-server'")))

(defvar eglot-server-programs)
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(likec4-mode . likec4--eglot-contact)))

(defvar lsp-language-id-configuration)
(defvar lsp--formatting-indent-alist)
(declare-function lsp-register-client "ext:lsp-mode" (client))
(declare-function make-lsp-client "ext:lsp-mode" (&rest args))
(declare-function lsp-stdio-connection "ext:lsp-mode" (command &optional test-command))
(declare-function lsp-activate-on "ext:lsp-mode" (&rest languages))
(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(likec4-mode . "likec4"))
  (add-to-list 'lsp--formatting-indent-alist '(likec4-mode . likec4-indent-offset))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection #'likec4--lsp-command
                                          (lambda () (and (likec4--lsp-command) t)))
    :activation-fn (lsp-activate-on "likec4")
    :notification-handlers (let ((h (make-hash-table :test #'equal)))
                             (puthash "likec4/onDidChangeModel" #'ignore h)
                             h)
    :download-server-fn (lambda (_client callback error-callback _update?)
                          (condition-case err
                              (progn (likec4-install-server) (funcall callback))
                            (error (funcall error-callback (error-message-string err)))))
    :server-id 'likec4)))

(provide 'likec4)
;;; likec4.el ends here
