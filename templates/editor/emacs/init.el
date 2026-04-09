;; Emacs Configuration
;; Add to ~/.emacs.d/init.el or ~/.emacs

;; ======================
;; Package Management
;; ======================
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; ======================
;; General Settings
;; ======================
(setq-default
 coding-system 'utf-8
 default-directory "~/"
 cursor-type 'bar
 column-number-mode t
 line-number-mode t
 show-trailing-whitespace t
 inhibit-startup-message t
 initial-scratch-message nil
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil
)

;; ======================
;; Indentation
;; ======================
(setq-default
 tab-width 2
 indent-tabs-mode nil
 c-basic-offset 2
 sh-basic-offset 2
 js2-basic-offset 2
 typescript-indent-level 2
 css-indent-offset 2
 python-indent-offset 4
 go-indent-offset 4
)

;; ======================
;; Whitespace
;; ======================
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq show-trailing-whitespace t)
(setq whitespace-style '(trailing space-before-tab indentation space-after-tab))
(global-whitespace-mode t)

;; ======================
;; UI Enhancements
;; ======================
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(setq use-file-dialog nil)
(setq-default fill-column 100)
(fringe-mode '(4 . 4))

;; ======================
;; Programming
;; ======================
(setq-default
 js-indent-level 2
 js2-indent-offset 2
 typescript-indent-level 2
 css-indent-offset 2
)

;; ======================
;; Useful Packages
;; ======================
(use-package company
  :ensure t
  :config (add-hook 'after-init-hook 'global-company-mode))

(use-package flycheck
  :ensure t
  :config (add-hook 'after-init-hook 'global-flycheck-mode))

(use-package prettier
  :ensure t
  :config
  (setq prettier-js-args '("--tab-width" "2" "--single-quote" "true" "--trailing-comma" "es5"))
  (add-hook 'web-mode-hook #'prettier-js-mode))

(use-package editorconfig
  :ensure t
  :config (editorconfig-mode 1))

;; ======================
;; Language-Specific
;; ======================

;; JavaScript/TypeScript
(use-package js2-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
  (add-to-list 'interpreter-mode-alist '("node" . js2-mode)))

(use-package typescript-mode
  :ensure t
  :mode "\\.ts\\'")

;; Python
(use-package python
  :ensure t
  :config
  (setq python-indent-offset 4))

;; Go
(use-package go-mode
  :ensure t
  :config
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save)
  (add-hook 'go-mode-hook #'lsp-deferred))

;; ======================
;; Key Bindings
;; ======================
(global-set-key (kbd "M-w") 'kill-ring-save)
(global-set-key (kbd "C-s") 'save-buffer)
(global-set-key (kbd "M-/") 'company-complete)
