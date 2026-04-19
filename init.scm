(require-builtin steel/random as rand::)

(require "cogs/keymaps.scm")
(require "cogs/switcheroo.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/configuration.scm")
(require "helix.scm")
(require "splash.scm")
(require "focus.scm")
(require "scooter/scooter.scm")
(require "streal/streal.scm")
(require (prefix-in hxnav. "cogs/hx-zellij-navigator.scm"))
(require "nrepl.scm")
(require (only-in "cogs/projects.scm" project-switch project-add project-add-current project-delete project-discover))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Picking one from the possible themes is _fine_
(define possible-themes '("spacemacs" "catppuccin_macchiato" "kanagawa" "focus_nova" "gruvbox_dark_hard" "ayu_dark" ))

(define (select-random lst)
  (let ([index (rand::rng->gen-range 0 (length lst))]) (list-ref lst index)))

(define (randomly-pick-theme options)
  ;; Randomly select the theme from the possible themes list
  (helix.theme (select-random options)))

(randomly-pick-theme possible-themes)

;;;;;;;;;;;;;;;;;;;;;;;; Default modes ;;;;;;;;;;;;;;;;;;;;;;;

;; Enable the recentf snapshot, will watch every 2 minutes for active files,
;; and flush those down to disk
(recentf-snapshot)

;;;;;;;;;;;;;;;;;;;;;;;;;; Keybindings ;;;;;;;;;;;;;;;;;;;;;;;

;; To remove a binding, set it to 'no_op
;; For example, this will make it impossible to enter insert mode:
;; (hash "normal" (hash "i" 'no_op))
;; nrepl keys under Space+n — split `keymap` calls so `A-ret` / `select` expand
;; cleanly (single `(normal ...)` with C-r + space + A-ret tripped BadSyntax).
(keymap (global)
        (normal (C-r (f ":recentf-open-files"))
                (space (l ":load-buffer")
                       (o ":eval-sexpr")
                       (n (C ":nrepl-connect")
                          (D ":nrepl-disconnect")
                          (J ":nrepl-jack-in")
                          (L ":nrepl-load-file")
                          (b ":nrepl-eval-buffer")
                          (l ":nrepl-lookup-picker")
                          (m ":nrepl-eval-multiple-selections")
                          (p ":nrepl-eval-prompt")
                          (s ":nrepl-eval-selection")))))

(keymap (global)
        (normal (A-ret ":nrepl-eval-selection")))

(keymap (global)
        (select (space (n (C ":nrepl-connect")
                          (D ":nrepl-disconnect")
                          (J ":nrepl-jack-in")
                          (L ":nrepl-load-file")
                          (b ":nrepl-eval-buffer")
                          (l ":nrepl-lookup-picker")
                          (m ":nrepl-eval-multiple-selections")
                          (p ":nrepl-eval-prompt")
                          (s ":nrepl-eval-selection")))))

(keymap (global)
        (select (A-ret ":nrepl-eval-selection")))

;; C-[hjkl]: Helix splits first, then scripts/nav.sh (Zellij / other) — see AGENTS.md
(keymap (global)
        (normal
          (C-h ":hxnav.move-left")
          (C-l ":hxnav.move-right")
          (C-j ":hxnav.move-down")
          (C-k ":hxnav.move-up"))
        (insert
          (C-h ":hxnav.move-left")
          (C-l ":hxnav.move-right")
          (C-j ":hxnav.move-down")
          (C-k ":hxnav.move-up"))
        (select
          (C-h ":hxnav.move-left")
          (C-l ":hxnav.move-right")
          (C-j ":hxnav.move-down")
          (C-k ":hxnav.move-up")))

(define scm-keybindings (hash "insert" (hash "ret" ':scheme-indent "C-l" ':insert-lambda)))

;; Grab whatever the existing keybinding map is
(define standard-keybindings (deep-copy-global-keybindings))

(define file-tree-base (deep-copy-global-keybindings))

(merge-keybindings standard-keybindings scm-keybindings)
(merge-keybindings file-tree-base FILE-TREE-KEYBINDINGS)

;; <scratch> + <doc id> is probably the best way to handle this?
(set-global-buffer-or-extension-keymap (hash "scm" standard-keybindings FILE-TREE file-tree-base))

;;;;;;;;;;;;;;;;;;;;;;;;;; Options ;;;;;;;;;;;;;;;;;;;;;;;;;;;

(file-picker (fp-hidden #f))
(cursorline #t)
(soft-wrap (sw-enable #t))

(randomly-pick-theme possible-themes)

;; New LSP definitions
(define-lsp "steel-language-server" (command "steel-language-server") (args '()))
(define-lsp "rust-analyzer" (config (experimental (hash 'testExplorer #t))))

;; New language definition
(define-language "scheme"
                 (formatter (command "raco") (args '("fmt" "-i")))
                 (auto-format #true)
                 (language-servers '("steel-language-server")))

; (when (equal? (command-line) '("hxx"))
;   (show-splash))

;; Probably should be a symbol?
; (register-hook! 'post-insert-char 'prompt-on-char-press)
