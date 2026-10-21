# likec4.el

Emacs major mode for [LikeC4](https://likec4.dev) (`.c4`, `.likec4`, `.like-c4`)
with language server registration for both [Eglot](https://github.com/joaotavora/eglot)
and [lsp-mode](https://emacs-lsp.github.io/lsp-mode/).

The language server provides completion, diagnostics, go-to-definition,
hover and semantic highlighting; the mode itself provides basic font-lock,
comments and brace indentation.

## Prerequisites

```sh
npm install -g likec4
```

The server is started as `likec4 lsp --stdio` (customize `likec4-lsp-command`).

## Vanilla Emacs

Emacs 30+ (`use-package` `:vc`):

```elisp
(use-package likec4
  :vc (:url "https://github.com/drlkf/likec4.el" :rev :newest)
  :hook (likec4-mode . eglot-ensure)) ; or #'lsp with lsp-mode
```

Emacs 29: `M-x package-vc-install RET https://github.com/drlkf/likec4.el`, then:

```elisp
(add-hook 'likec4-mode-hook #'eglot-ensure)
```

## Doom Emacs

`packages.el`:

```elisp
(package! likec4 :recipe (:host github :repo "drlkf/likec4.el"))
```

`config.el`:

```elisp
(use-package! likec4
  :defer t
  :hook (likec4-mode . lsp!)) ; uses lsp-mode or eglot per the :tools lsp module
```

## Spacemacs

A layer is shipped in `spacemacs/likec4`. Link it into your private layers:

```sh
ln -s /path/to/likec4.el/spacemacs/likec4 ~/.emacs.d/private/likec4
```

Then in `dotspacemacs-configuration-layers`:

```elisp
lsp
(likec4 :variables likec4-backend 'lsp) ; or 'eglot, or nil
```

Without the layer, add to `dotspacemacs-additional-packages`:

```elisp
(likec4 :location (recipe :fetcher github :repo "drlkf/likec4.el"))
```

and `(add-hook 'likec4-mode-hook #'lsp-deferred)` in `dotspacemacs/user-config`.

## Tests

```sh
emacs -Q --batch -L . -l test/likec4-test.el -f ert-run-tests-batch-and-exit
```

## License

GPL-3.0-or-later.
