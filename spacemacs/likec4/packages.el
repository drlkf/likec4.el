;;; packages.el --- likec4 layer packages file for Spacemacs -*- lexical-binding: t; -*-

;;; Code:

(defconst likec4-packages
  '((likec4 :location (recipe :fetcher github :repo "drlkf/likec4.el"))))

(defun likec4/init-likec4 ()
  (use-package likec4
    :defer t
    :init
    (add-hook 'likec4-mode-hook #'spacemacs//likec4-setup-backend)))

;;; packages.el ends here
