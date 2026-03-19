# Helix Editor Configuration

[中文说明](README.zh-CN.md)

Xing Wenju <linuxing3@qq.com> — A self-taught coder for fun

Personal [Helix](https://helix-editor.com/) editor configuration with
[Steel](https://github.com/mattwparas/steel) plugin system (Scheme scripting),
Zellix integration, and Vim-style motion emulation.

## Overview

This repo contains everything needed to run a heavily customized Helix setup on
**UOS (aarch64-linux)** with the Zellij terminal multiplexer.

### Key Features

- **Steel Plugin System** — Scheme-based scripting via `.scm` files
- **Embedded Terminal** — PTY-backed terminal inside Helix (`term.scm`)
- **Vim Motion Emulation** — Full `d`, `c`, `y`, `f/t`, visual-line motions (`vim/`)
- **File Tree** — Side-panel file browser (`cogs/file-tree.scm`)
- **Recent Files Picker** — Auto-snapshot & quick-open (`cogs/recentf.scm`)
- **Git Status Picker** — In-editor git status view (`cogs/git-status-picker.scm`)
- **Splash Screen** — Startup art with quick hints (`splash.scm`)
- **Focus Mode** — Distraction-free editing by clipping margins (`focus.scm`)
- **Scheme Indent** — Smart S-expression indentation (`cogs/scheme-indent.scm`)
- **Spacemacs Theme** — Port of the Spacemacs color scheme (`cogs/themes/spacemacs.scm`)
- **Zellix Workflow** — NuShell-driven Helix + Zellij integration (yazi, lazygit, project switcher, etc.)
- **Nix Dev Shell** — `flake.nix` + direnv for reproducible tooling

## Directory Structure

```
~/.config/helix/
├── config.toml          # Core Helix configuration (theme, keys, LSP, etc.)
├── languages.toml       # Language server & formatter definitions
├── init.scm             # Steel entry point — loads packages, sets theme/keys
├── helix.scm            # Core Steel functions (eval, git, shell, minor modes)
├── keymaps.scm          # Steel keymap helpers loaded by init.scm
├── cog.scm              # Steel package manifest (dependencies)
├── splash.scm           # Startup splash screen component
├── focus.scm            # Focus/zen mode component
├── term.scm             # Embedded terminal (requires steel-pty dylib)
│
├── cogs/                # Plugin modules (git submodule: mattwparas/helix-config)
│   ├── package.scm      #   Package loader & registry
│   ├── keymaps.scm      #   Keymap merge/copy utilities & DSL
│   ├── file-tree.scm    #   File tree side panel
│   ├── recentf.scm      #   Recent file picker (auto-snapshot)
│   ├── git-status-picker.scm  # Git status integrated picker
│   ├── scheme-indent.scm      # S-expression smart indent
│   ├── helix-ext.scm    #   Extended eval/prompt commands
│   ├── picker.scm       #   Generic picker component
│   ├── labelled-buffers.scm   # Named buffer management
│   └── themes/spacemacs.scm   # Spacemacs theme
│
├── vim/                 # Vim motion emulation layer
│   ├── init.scm         #   Vim keymap bootstrap
│   ├── utils.scm        #   Shared utilities
│   ├── normal-motions.scm   # Normal mode motions
│   ├── visual-motions.scm   # Visual mode motions
│   ├── delete-motions.scm   # d-prefixed delete motions
│   ├── change-motions.scm   # c-prefixed change motions
│   ├── yank-motions.scm     # y-prefixed yank motions
│   └── key-emulation.scm   # Key translation helpers
│
├── icons/nerd.toml      # Nerd Font icon mappings
├── actions/             # Editor action configs per language (cpp, go, lua, rust, markdown)
├── snippets/            # Code snippets (cpp, go, js, markdown, nix, reactjs)
├── scripts/             # Helper shell scripts (hx-ala, hx-desktop, ime-switch, etc.)
├── doc/                 # Reference docs (language-server.md, deno languages.toml)
├── tests/               # Test source files for action templates
├── tutors/              # Tutorial content (zh_cn)
│
├── flake.nix            # Nix flake dev shell (Node.js / Bun)
├── flake.lock           # Nix flake lock file
├── .envrc               # direnv integration (`use flake`)
├── justfile             # Just task runner (nix repl)
└── AGENTS.md            # Agentic coding assistant guidance
```

## Steel Plugin System

This configuration uses the **Steel** scripting engine — a Scheme dialect
embedded in the Helix fork by [mattwparas](https://github.com/mattwparas/helix).

### Entry Points

| File | Role |
|------|------|
| `init.scm` | Main entry — loads packages, sets theme, defines keybindings |
| `helix.scm` | Core library — eval, git helpers, shell, minor mode macros |
| `keymaps.scm` | Alternate keymap definitions loaded from `cogs.hx/` |
| `cog.scm` | Package manifest — declares `steel-pty` and `helix-file-watcher` deps |

### Packages (loaded via `load-package`)

| Package | Description |
|---------|-------------|
| `term.scm` | Embedded PTY terminal (`:open-term`, `:new-term`, `xplr`) |
| `cogs/file-tree.scm` | File tree with custom keybindings |
| `cogs/recentf.scm` | Recent file picker with background snapshotting |
| `cogs/git-status-picker.scm` | Git status as a picker |
| `cogs/scheme-indent.scm` | Smart Scheme/Lisp indentation on `Enter` |
| `cogs/helix-ext.scm` | `eval-buffer`, `evalp` prompt, thread-safe context |

### Installing Dependencies

```bash
# Install the forge CLI
cargo install --git https://github.com/mattwparas/steel.git steel-forge

# Install plugin dependencies (steel-pty, helix-file-watcher)
forge install
```

## Vim Emulation

The `vim/` directory provides a nearly complete Vim motion layer:

- **Normal mode** — `h/j/k/l`, `w/e/b`, `f/F/t/T`, `G`, `%`, `0/$`
- **Visual mode** — `v`, `V` (visual-line), visual block motions
- **Operators** — `d{motion}`, `c{motion}`, `y{motion}` with full inner/around text objects
- **Undo** — Vim-compatible undo behavior

To enable, add `(require "vim/init.scm")` in your `init.scm`.

## Keybindings (config.toml)

### Function Keys

| Key | Normal | Insert |
|-----|--------|--------|
| `F1` | Format | Format |
| `F2` | Rename symbol | Rename symbol |
| `F3` | Lazygit (Zellij float) | Lazygit |
| `F4` | Yazi file finder | Yazi |
| `F5` | Justfile runner | Justfile |
| `F6` | Project switcher | Project switcher |
| `F7-F10` | DAP debug | — |
| `F11` | Go to definition | — |
| `F12` | Go to implementation | — |

### Space Menu (Normal Mode)

| Prefix | Key | Action |
|--------|-----|--------|
| `space` | `space` | Command mode |
| `space` | `.` | File picker (cwd) |
| `space f` | `y/n/p/t/g` | Yazi / nnn / project / terminal / ripgrep |
| `space b` | `b/n/v/h/c/o` | Buffer picker / new / vsplit / hsplit / close / only |
| `space c` | `a/r/f/i/s` | Code action / rename / format / inlay hints / switcheroo |
| `space t` | `a-p` | Theme switcher |
| `space l` | `a/h/r/m/j/s/t/g` | AI / home-manager / remap / make / just / sh / multitask / tangle |
| `space e` | `a/w/f/n/p` | Emacsclient / zk notes / glow preview |
| `space o` | `g/p/a/t` | Open tab: lazygit / ipython / opencode / shell |
| `space r` | `p/a/t/1-3/l/h` | Send selection to tab / floating / pane |

### Zellij Integration

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Move focus between Zellij panes |
| `C-A-Esc` | Send current line to right pane |
| `C-A-Space` | Send full line to right pane |
| `C-a + n/h/v/z/m` | New pane / split down / split right / fullscreen / neomutt |

## Languages & Formatters

Configured in `languages.toml`:

| Language | Formatter | LSP |
|----------|-----------|-----|
| Rust | `rustfmt` | `rust-analyzer` |
| Go | — | `gopls` + `golangci-lint-lsp` |
| Python | `ruff format` | `pylsp` / `ruff` |
| Lua | `stylua` | `lua-language-server` |
| JS/TS | `prettier` | `typescript-language-server` / `vscode-eslint` |
| JSON/JSONC | `prettier` | `vscode-json-language-server` |
| Typst | `typst c` | `typst-lsp` |
| Scheme | `raco fmt` | `steel-language-server` |
| Nix | — | `nil` |

## Prerequisites

- [Helix (Steel fork)](https://github.com/mattwparas/helix) — `cargo xtask steel`
- [Zellij](https://zellij.dev/) terminal multiplexer
- [Zellix](https://github.com/user/zellix) NuShell plugin system (`~/.config/zellix`)
- [Nix](https://nixos.org/) + [direnv](https://direnv.net/) (optional, for dev shell)
- [steel-pty](https://github.com/mattwparas/steel-pty) (for embedded terminal)

## License

Personal configuration — feel free to reference or adapt.
