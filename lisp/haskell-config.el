;;; haskell-config --- My personal configurations for haskell-mode

;; Copyright (C) 2012 John Wiegley

;; Author: John Wiegley <jwiegley@gmail.com>
;; Created: 09 Aug 2012
;; Version: 1.0
;; Keywords: haskell programming awesomeness
;; X-URL: https://github.com/jwiegley/dot-emacs

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; My personal configurations for haskell-mode.  Requires my `use-package'
;; macro from:
;;
;;     https://github.com/jwiegley/use-package

(require 'use-package)

(use-package haskell-mode
  :mode ("\\.l?hs\\'" . haskell-mode)
  :config
  (progn
    (use-package inf-haskell
      :config
      (progn
        (defun my-inferior-haskell-find-haddock (sym)
          (interactive
           (let ((sym (haskell-ident-at-point)))
             (list (read-string
                    (if (> (length sym) 0)
                        (format "Find documentation of (default %s): " sym)
                      "Find documentation of: ")
                    nil nil sym))))
          (flet ((browse-url (url &rest args) (w3m-browse-url url)))
            (inferior-haskell-find-haddock sym)
            (goto-char (point-min))
            (when (re-search-forward (concat "^" sym " :: ") nil t)
              (goto-char (line-beginning-position))
              (recenter-top-bottom))))

        (defun my-inferior-haskell-find-definition ()
          (interactive)
          (inferior-haskell-find-definition (haskell-ident-at-point))
          (forward-char -1))

        (defun my-inferior-haskell-type (expr &optional insert-value)
          (interactive
           (let ((sym (haskell-ident-at-point)))
             (list (if current-prefix-arg
                       sym
                     (read-string (if (> (length sym) 0)
                                      (format "Show type of (default %s): " sym)
                                    "Show type of: ")
                                  nil nil sym))
                   current-prefix-arg)))
          (message (inferior-haskell-type expr insert-value)))))

    (use-package ghc
      :load-path "site-lisp/ghc-mod/elisp/"
      :commands ghc-init
      :init
      (progn
        (setq ghc-module-command (expand-file-name "~/.cabal/bin/ghc-mod"))
        (add-hook 'haskell-mode-hook 'ghc-init)))

    (use-package scion
      :disabled t
      :load-path "site-lisp/scion/emacs/"
      :init
      (progn
        ;; if ./cabal/bin is not in your $PATH
        (setq scion-program (expand-file-name "~/.cabal/bin/scion-server"))

        ;; Use ido-mode completion (matches anywhere, not just beginning)
        ;;
        ;; WARNING: This causes some versions of Emacs to fail so badly that
        ;; Emacs needs to be restarted.
        (setq scion-completing-read-function 'ido-completing-read)))

    (eval-after-load "haskell-doc"
      '(defun haskell-doc-sym-doc (sym)
        (unless (string= "" sym)
          (let ((result (ignore-errors
                          (inferior-haskell-type sym))))
            (if (and result (string-match " :: " result))
                result
              (setq result (inferior-haskell-kind sym))
              (and result (string-match " :: " result) result))))))

    (defadvice haskell-ident-at-point
      (around my-haskell-ident-at-point activate)
      (save-excursion
        (skip-chars-backward " \t")
        ad-do-it))

    (defun my-haskell-mode-hook ()
      (bind-key "C-M-x" 'inferior-haskell-send-decl haskell-mode-map)
      (unbind-key "C-x C-d" haskell-mode-map)

      (when (featurep 'inf-haskell)
        ;; Use C-u C-c C-t to auto-insert a function's type above it
        (bind-key "C-c C-t" 'my-inferior-haskell-type haskell-mode-map)
        (bind-key "C-c C-k" 'inferior-haskell-kind haskell-mode-map)
        (bind-key "C-c C-i" 'inferior-haskell-info haskell-mode-map)
        (bind-key "C-c C-d" 'my-inferior-haskell-find-haddock haskell-mode-map)
        (bind-key "M-." 'my-inferior-haskell-find-definition haskell-mode-map))

      (when (featurep 'scion)
        ;; Whenever we open a file in Haskell mode, also activate Scion
        (scion-mode 1)
        ;; Whenever a file is saved, immediately type check it and highlight
        ;; errors/warnings in the source.
        (scion-flycheck-on-save 1))

      (setq haskell-saved-check-command haskell-check-command)
      (flymake-mode 1)

      (bind-key "C-c w" 'flymake-display-err-menu-for-current-line
                haskell-mode-map)
      (bind-key "C-c *" 'flymake-start-syntax-check haskell-mode-map)
      (bind-key "M-n" 'flymake-goto-next-error haskell-mode-map)
      (bind-key "M-p" 'flymake-goto-prev-error haskell-mode-map))

    (add-hook 'haskell-mode-hook 'my-haskell-mode-hook)))

(provide 'haskell-config)

;;; haskell-config.el ends here
