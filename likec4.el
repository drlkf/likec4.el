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

(defcustom likec4-lsp-command '("likec4" "lsp" "--stdio")
  "Command and arguments used to start the LikeC4 language server."
  :type '(repeat string))

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
  (setq-local electric-indent-chars (append "{}()" electric-indent-chars)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(?:c4\\|likec4\\|like-c4\\)\\'" . likec4-mode))

(defun likec4--eglot-contact (&optional _interactive)
  "Return the Eglot contact for the LikeC4 language server."
  likec4-lsp-command)

(defvar eglot-server-programs)
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(likec4-mode . likec4--eglot-contact)))

(defvar lsp-language-id-configuration)
(declare-function lsp-register-client "ext:lsp-mode" (client))
(declare-function make-lsp-client "ext:lsp-mode" (&rest args))
(declare-function lsp-stdio-connection "ext:lsp-mode" (command &optional test-command))
(declare-function lsp-activate-on "ext:lsp-mode" (&rest languages))
(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(likec4-mode . "likec4"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection (lambda () likec4-lsp-command))
    :activation-fn (lsp-activate-on "likec4")
    :server-id 'likec4)))

(provide 'likec4)
;;; likec4.el ends here
