Title: How to develop with Common Lisp in Guix
Date: 2024-10-14
Category: Guix
tags: guix, common-lisp

I create a #guix project in a directory like `/home/mzan/fun-projects/snow`.

This is the `guix.scm` file

```scheme
(use-modules
  ((guix licenses) #:prefix license:)
  (guix packages)
  (guix download)
  (guix gexp)
  (guix git-download)
  (guix build-system asdf)
  (guix build-system gnu)
  (guix utils)
  (gnu packages)
  (gnu packages bash)
  (gnu packages admin)
  (gnu packages autotools)
  (gnu packages base)
  (gnu packages lisp)
  (gnu packages lisp-xyz)
  (gnu packages commencement))

(define %source-dir (dirname (current-filename)))

(package
    (name "snow-assembler")
    (version "0.1")
    (source (local-file %source-dir #:recursive? #t))
    (build-system asdf-build-system/sbcl)
    (native-inputs
     (list
        sbcl
        sbcl-slynk
        sbcl-agnostic-lizard

        sbcl-defstar
        sbcl-trivia
        sbcl-alexandria
        sbcl-trivial-types
        sbcl-cl-str
        sbcl-parse-float
        sbcl-iterate
        sbcl-let-plus
        sbcl-array-operations
        sbcl-sdl2
        sbcl-trivial-benchmark
        sbcl-random-state))
    (outputs '("out" "lib"))
    (synopsis "Generate a fractal image")
    (description
     "Generate a fractal image.")
    (home-page "")
    (license license:lgpl3+))
```

Note that all used #commonlisp packages are defined in the project, and that the `sbcl-sdl2` package will take care to install also the external (i.e. C) library. `sbcl-...` packages are needed only for development inside Emacs.

This is the `.envrc` file to use for [direnv](https://direnv.net/).

```
eval $(guix shell --search-paths)
export GUILE_LOAD_PATH="$PWD:$GUILE_LOAD_PATH"
```
It will be enable with `direnv allow` in the shell, or with `envrc-allow` in Emacs. 

In case of changes in the `guix.scm` file, it can be reloaded with `direnv reload` in the shell, or `envrc-reload` in Emacs.

This is the #commonlisp #asdf project file `snow-assembler.asd`

```lisp
(asdf:defsystem "snow-assembler"
  :description "Draw a fractal"

  :author "mzan@dokmelody.org"
  :license  "LGPL-3.0-or-later"
  :depends-on (
     "alexandria"
     "trivial-types"
     "defstar"
     "iterate"
     "str"
     "let-plus"
     "array-operations"
     "sdl2"
     "cl-opengl"
     "cffi"
     "trivial-benchmark"
     "random-state")

  :components ((:file "snow-assembler")))
```

In this file, I'm reusing the packages I defined in `guix.scm`.

In `~/.sbclrc` I instruct #asdf that there is a system (i.e. a #commonlisp project) in the directory of the project. I'm using something like this

```lisp
(require :asdf)

; NOTE: all subdirectories of specified directories are searched for asdf project files
(asdf:initialize-source-registry
  `(:source-registry
     (:tree "/home/mzan/fun-projects/snow")
     (:tree "/home/mzan/communities")
     :inherit-configuration))
```

I launch Emacs. I open the `snow-assembler.asd` file. I make sure that the #guix environment is loaded executing the Emacs function `envrc-reload`. 

I start a connection to `sbcl` using `sly`. 

I open the #sbcl #commonlisp REPL, and I load the system with `(asdf:load-system "snow-assembler")`.

Now, I'm ready to code in #commonlisp, using #emacs and #sly.

# HashTags

- #LearnedTask.
- #guix


