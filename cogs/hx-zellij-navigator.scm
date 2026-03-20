;;; Helix ↔ multiplexer navigation (Zellij-first), modeled on
;;; https://github.com/piotrkwarcinski/hx-tmux-navigator
;;;
;;; Try `jump_view_*` inside Helix; if the focused view id does not change,
;;; run ~/.config/helix/scripts/nav.sh <direction> (Zellij, Kitty, Wezterm, …).

(require-builtin steel/process)
(require (prefix-in hx.static. "helix/static.scm"))
(require (prefix-in hx.editor. "helix/editor.scm"))

(define (nav-script-path)
  (string-append (canonicalize-path "~") "/.config/helix/scripts/nav.sh"))

(define (exec-outer-nav dir)
  (let* ([cmd (command "sh" (list (nav-script-path) dir))]
         [child-result (spawn-process cmd)]
         [child (Ok->value child-result)])
    (wait child)))

(define (move hx-jump-fn dir)
  (define view-p (hx.editor.editor-focus))
  (hx-jump-fn)
  (define view-n (hx.editor.editor-focus))
  (when (equal? view-n view-p)
    (exec-outer-nav dir)))

(define (move-right)
  (move hx.static.jump_view_right "right"))

(define (move-left)
  (move hx.static.jump_view_left "left"))

(define (move-down)
  (move hx.static.jump_view_down "down"))

(define (move-up)
  (move hx.static.jump_view_up "up"))

(provide move-right move-left move-down move-up)
