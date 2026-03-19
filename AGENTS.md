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

## Notes for agents

- This repository is a Helix config; changes often involve TOML and JSON.
- Use `:format` in Helix (bound to `F1`) when formatting is needed.
- Avoid repo-wide formatting. Keep changes scoped to relevant files only.
