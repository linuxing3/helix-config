(require "cogs/keymaps.scm")
(require (only-in "cogs/file-tree.scm" FILE-TREE-KEYBINDINGS FILE-TREE))
(require (only-in "cogs/recentf.scm" recentf-open-files get-recent-files recentf-snapshot))

;; Set the global keybinding for now
(add-global-keybinding (hash "normal" (hash "C-r" (hash "f" ":recentf-open-files"))))

(define scm-keybindings (hash "insert" (hash "ret" ':scheme-indent "C-l" ':insert-lambda)))

;; Grab whatever the existing keybinding map is
(define standard-keybindings (deep-copy-global-keybindings))

(define file-tree-base (deep-copy-global-keybindings))

(merge-keybindings standard-keybindings scm-keybindings)
(merge-keybindings file-tree-base FILE-TREE-KEYBINDINGS)

(set-global-buffer-or-extension-keymap (hash "scm" standard-keybindings FILE-TREE file-tree-base))
	
