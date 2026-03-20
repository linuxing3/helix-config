# AGENTS.md
# Repository guidance for agentic coding assistants

This repository is a Helix editor configuration. It is not a typical application
repo with a build system, tests, or a single language. Use the guidance below
to keep changes consistent with existing patterns.

## Build, lint, test

There is no standard build/lint/test command defined at the repo root.
I could not find `package.json`, `Makefile`, `justfile`, or CI workflows.
If you need commands, see these editor action configs instead:

- `/home/Designers/.config/helix/actions/lua.json`
  - `xmake r`
  - `xmake build`
  - `xmake build ; xmake run`
- `/home/Designers/.config/helix/actions/rust.json`
  - `cargo r`

No single-test invocation pattern is documented in this repo.
If you add tests in a project that lives under this config, you should also
update this file with the appropriate commands.

## Formatting and linting tools (implicit style)

There is no explicit style guide for imports, naming, or error handling.
Style is implied through Helix language configuration and formatter choices.

Primary sources:
- `/home/Designers/.config/helix/languages.toml`
- `/home/Designers/.config/helix/doc/deno_helix_languages.toml`
- `/home/Designers/.config/helix/config.toml`

### Formatters configured by language

- Rust: `rustfmt`
- JSON / JSONC: `prettier --write --stdin-filepath %{buffer_name}`
- Python: `ruff format`
- Lua: `stylua`
- Typst: `typst c`

Auto-format is enabled for several languages in `languages.toml`.

### Linting / diagnostics

- Deno LSP: `lint = true` for JS/TS/JSX/TSX in
  `/home/Designers/.config/helix/doc/deno_helix_languages.toml`
- LSPs configured for linting or diagnostics include:
  - `golangci-lint-lsp` (Go)
  - `vscode-eslint-language-server` (JS/TS)
  - `typos-lsp` (typos)

### Indentation

- Many languages use 4-space indentation (JS/TS/JSX/TSX, Lua, Vue, Svelte).
  See `/home/Designers/.config/helix/languages.toml`.
- Deno language definitions use 2-space indentation for JS/TS/JSX/TSX.
  See `/home/Designers/.config/helix/doc/deno_helix_languages.toml`.

### Wrapping

- Markdown, LaTeX, Typst: text width 80 with soft wrap enabled.
  See `/home/Designers/.config/helix/languages.toml`.

## Code style guidance (practical defaults)

Because there is no repo-wide style doc, follow these defaults when editing:

- Prefer existing patterns in nearby files.
- Match indentation and line wrapping rules from `languages.toml`.
- Do not introduce new formatters or linters without updating this document.
- Avoid reformatting unrelated files.

### Imports

- Keep import ordering consistent with the file you are editing.
- Do not reorder imports unless you are touching the import block for a reason.
- Avoid unused imports; remove if you add and don’t use them.

### Naming

- Use existing naming conventions in the language and file.
- Do not introduce new abbreviations unless the file already uses them.
- Prefer descriptive names over short or cryptic ones.

### Types

- Prefer explicit, idiomatic types for the language (e.g., Rust/TS).
- Avoid type suppressions (`as any`, `@ts-ignore`, `@ts-expect-error`).

### Error handling

- Handle errors explicitly; do not swallow exceptions.
- Favor returning errors or logging them rather than empty `catch` blocks.

## Cursor / Copilot rules

No `.cursor/rules/`, `.cursorrules`, or
`.github/copilot-instructions.md` were found in this repo.
If you add them later, update this file to include their guidance.

## Native extensions (dylibs)

This Helix config uses Steel scripting with native dynamic libraries.
The dylib source repos are **not** submodules; they are built out-of-tree
and installed to `~/.local/share/steel/native/`.

### steel-pty (embedded terminal)

Provides `:open-term`, `:new-term`, `:kill-active-terminal`, etc.

**Quick build** (requires `nix` in PATH):

```bash
./scripts/build-steel-pty.sh
```

**Manual build**:

```bash
git clone --depth 1 https://github.com/mattwparas/steel-pty.git /tmp/steel-pty
cd /tmp/steel-pty
nix-shell -p rustc cargo pkg-config git openssl openssl.dev \
  --run "cargo-steel-lib"
```

- `cargo-steel-lib` (from Steel nix package) builds the cdylib and
  copies `libsteel_pty.so` to `~/.local/share/steel/native/`.
- If cargo fails to fetch the wezterm Git dependency, ensure
  `~/.cargo/config.toml` contains:
  ```toml
  [net]
  git-fetch-with-cli = true
  ```
- Build takes ~8 min on aarch64. Restart Helix after installing.

### Rebuild triggers

Rebuild steel-pty when:
- Helix or Steel is upgraded (ABI may change)
- `term.scm` is updated from upstream
- `:open-term` starts failing with `TypeMismatch` errors

### steel-nrepl ([nrepl.hx](https://github.com/waddie/nrepl.hx))

nREPL client for Clojure/Babashka/Python (`:nrepl-connect`, `:nrepl-jack-in`, etc.).

**Build** (Rust via nix-shell; cargo need not be on default `PATH`):

```bash
git clone --depth 1 https://github.com/waddie/nrepl.hx.git /tmp/nrepl.hx
cd /tmp/nrepl.hx
nix-shell -p rustc cargo pkg-config openssl --run "cargo build --release"
./install.sh
```

Copy `libsteel_nrepl.so` into `~/.local/share/steel/native/` if you keep other
dylibs there (upstream `install.sh` also places a copy under `~/.steel/native/`).

### scooter_hx ([scooter.hx](https://github.com/thomasschafer/scooter.hx))

Find-and-replace plugin (`:scooter`, `:scooter-new`). You already have
`libscooter_hx.so` under `~/.local/share/steel/native/`.

Scheme sources must live where Steel resolves `(require "scooter/scooter.scm")` —
typically **`~/.steel/cogs/scooter/`** (this repo keeps `scooter/` under the
Helix config dir and symlinks that path to `~/.steel/cogs/scooter`).

**Update** (clone then copy `scooter.scm` + `ui/` into `scooter/`):

```bash
git clone --depth 1 https://github.com/thomasschafer/scooter.hx.git /tmp/scooter.hx
cp /tmp/scooter.hx/scooter.scm ~/.config/helix/scooter/scooter.scm
cp -r /tmp/scooter.hx/ui ~/.config/helix/scooter/
```

Or: `forge pkg install --git https://github.com/thomasschafer/scooter.hx.git`
(if you use Forge).

### streal.hx ([streal.hx](https://github.com/gllms/streal.hx))

Bookmark files per working directory and jump by number (`:streal-open`). Pure
Scheme — no dylib; nothing to add to `cog.scm`.

Keep `streal/streal.scm` under this Helix config (same layout as upstream’s
`(require "streal/streal.scm")`).

**Update** (clone then copy `streal.scm`):

```bash
git clone --depth 1 https://github.com/gllms/streal.hx.git /tmp/streal.hx
cp /tmp/streal.hx/streal.scm ~/.config/helix/streal/streal.scm
```

Or: `forge pkg install --git https://github.com/gllms/streal.hx.git`

### Helix ↔ Zellij navigation (hx-tmux-navigator style)

[hx-tmux-navigator](https://github.com/piotrkwarcinski/hx-tmux-navigator) jumps inside
Helix first (`jump_view_*`), then delegates to tmux. This config uses the same pattern
in `cogs/hx-zellij-navigator.scm`, but the outer step runs `scripts/nav.sh` so **Zellij**
(`zellij ac move-focus-or-tab`) and your other fallbacks (Kitty, Wezterm, oxwm, …) still work.

**Zellij**: do **not** bind `Ctrl+h/j/k/l` in `shared_except` (or any mode that should
forward keys to Helix). Those bindings were commented out in
`~/.config/home-manager/configs/zellij/config.kdl` — run `home-manager switch` so
`~/.config/zellij/config.kdl` updates. Use **Locked** mode (`Alt+z` in this config) or
Zellij’s pane/tab modes when you need multiplexer-only navigation without involving Helix.

### cog.scm

`cog.scm` declares which dylibs this config uses. It should list every dylib
you load, for example:

```scheme
(define dylibs '((#:name "steel-pty")
                 (#:name "steel-nrepl")
                 (#:name "scooter_hx")))
```

### Dylib search path

Steel / Helix look for `.so` files in (order may vary by build):
1. `~/.local/share/steel/native/`
2. `~/.steel/native/` (used by several plugin `install.sh` scripts; if you see
   `dylib not found: libscooter_hx` while the file exists under `.local/share`,
   copy or symlink the `.so` here as well)
3. `$STEEL_HOME/native/` (nix profile: `~/.nix-profile/lib/steel/native/`)

## Notes for agents

- This repository is a Helix config; changes often involve TOML, JSON,
  and Steel Scheme (`.scm`).
- Use `:format` in Helix (bound to `F1`) when formatting is needed.
- Avoid repo-wide formatting. Keep changes scoped to relevant files only.
- Self-improvement logs live in `.learnings/` — check before
  troubleshooting recurring issues.
