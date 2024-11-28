
(use-modules
  ((guix licenses) #:prefix license:)
  (guix packages)
  (guix download)
  (guix gexp)
  (guix git-download)
  (guix build-system copy)
  (guix build-system gnu)
  (guix utils)
  (gnu packages)
  (gnu packages bash)
  (gnu packages base)
  (gnu packages admin)
  (gnu packages autotools)
  (gnu packages base)
  (gnu packages commencement)
  (gnu packages docker)
  (gnu packages rsync)
  (gnu packages sync)
  (gnu packages rust-apps))

(define %source-dir (dirname (current-filename)))

(package
    (name "mzan-blog")
    (version "0.1")
    (source (local-file %source-dir #:recursive? #t))
    (build-system copy-build-system)
    (inputs
     (list
        docker-cli

        rsync
        rclone
        just  ; for tasks
        gnu-make
        ))
    (synopsis "Generate mzan.dokmelody.org blog")
    (description
     "Generate mzan.dokmelody.org blog")
    (home-page "")
    (license license:bsd-2))
