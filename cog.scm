(define package-name 'mattwparas-helix-package)
(define version "0.1.0")

;; steel-pty built manually via nix-shell + cargo-steel-lib (2026-03-19)
;; helix-file-watcher still disabled (requires separate build)
(define dependencies '())

(define dylibs '((#:name "steel-pty")))
