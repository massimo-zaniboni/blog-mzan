Massimo Zaniboni [personal blog](https://mzan.dokmelody.org).

## Build

The hosting environment is defined in `guix.scm`, i.e. it is Guix. `.envrc` load it.

Up to date in Guix there is no `hugo` packages, so `just build-image` will build a Docker image containing hugo.

`just --list` shows all commands for website maintanance. 

## Customizations

- The main params of website are in `hugo.toml`.
- The copyright info is in `layout/partials/site-footer.html`.
- The CSS settings in `static/custom.css`.
- Custom fonts are imported in `layouts/partials/head/custom.html`.






