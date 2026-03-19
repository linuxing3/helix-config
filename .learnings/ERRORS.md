# Errors

## [ERR-20260319-001] open-term

**Logged**: 2026-03-19T19:38:00+08:00
**Priority**: high
**Status**: resolved

### Summary
`:open-term` in Helix fails with `TypeMismatch: application not a
procedure: #<void>`

### Error
```
Error: TypeMismatch: application not a procedure: #<void>
```

### Context
- Command: `:open-term` in Helix command palette
- Root cause: `term.scm` calls `#%require-dylib "libsteel_pty"` which
  returns `#<void>` when `libsteel_pty.so` is not found, then functions
  like `create-native-pty-system!` are bound to `#<void>` instead of
  actual procedures.
- Environment: Helix 25.07.1, Steel 0.6.0 (in PATH) / 0.7.0
  (nix store), aarch64-linux (UOS)

### Suggested Fix
Build and install `libsteel_pty.so` — see LRN-20260319-001.

### Metadata
- Reproducible: yes
- Related Files: `term.scm`, `cog.scm`
- See Also: LRN-20260319-001

### Resolution
- **Resolved**: 2026-03-19T19:54:00+08:00
- **Notes**: Built steel-pty via `nix-shell` + `cargo-steel-lib`.

---

## [ERR-20260319-002] cargo-fetch-ssh-auth

**Logged**: 2026-03-19T19:42:00+08:00
**Priority**: medium
**Status**: resolved

### Summary
`cargo fetch` fails to clone wezterm Git dependency via SSH.

### Error
```
failed to authenticate when downloading repository:
ssh://git@github.com/mattwparas/wezterm.git
attempted ssh-agent authentication, but no usernames succeeded: `git`
```

### Context
- Command: `cargo fetch` (or `cargo build`) inside steel-pty
- Cause: `Cargo.toml` references wezterm via `git = "https://..."` but
  cargo internally tries SSH for GitHub; no SSH agent configured in
  nix-shell.
- Fix: Set `[net] git-fetch-with-cli = true` in `~/.cargo/config.toml`
  so cargo delegates to the system `git` binary, which uses HTTPS.

### Suggested Fix
Already resolved by creating `~/.cargo/config.toml`.

### Metadata
- Reproducible: yes (on systems without SSH agent)
- Related Files: `~/.cargo/config.toml`
- See Also: LRN-20260319-001

### Resolution
- **Resolved**: 2026-03-19T19:45:00+08:00
- **Notes**: Added `[net] git-fetch-with-cli = true` to cargo config.

---
