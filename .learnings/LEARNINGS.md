# Learnings

## [LRN-20260319-001] best_practice

**Logged**: 2026-03-19T19:54:00+08:00
**Priority**: high
**Status**: resolved

### Summary
Building steel-pty native dylib on aarch64-linux (UOS) requires nix-shell
for Rust toolchain and specific cargo/git workarounds.

### Details
The Helix `:open-term` command failed with `TypeMismatch: application not a
procedure: #<void>` because `term.scm` depends on `libsteel_pty.so` via
`#%require-dylib "libsteel_pty"`. The dylib was never compiled because:

1. `cog.scm` had `dependencies` and `dylibs` set to `'()` — forge's
   libgit2 binding lacks SSH auth callback, and no Rust toolchain was
   installed.
2. `load-package "term.scm"` silently fails at startup, but calling
   `:open-term` at runtime invokes unloaded functions → `#<void>` error.

### Resolution Steps

1. **Clone steel-pty**:
   ```
   git clone --depth 1 https://github.com/mattwparas/steel-pty.git /tmp/steel-pty
   ```

2. **Configure cargo to use git CLI** (avoids SSH auth failure for
   wezterm dependency):
   ```toml
   # ~/.cargo/config.toml
   [net]
   git-fetch-with-cli = true
   ```

3. **Build with nix-shell + cargo-steel-lib**:
   ```bash
   cd /tmp/steel-pty
   nix-shell -p rustc cargo pkg-config git openssl openssl.dev \
     --run "cargo-steel-lib"
   ```
   - Uses Rust from nixpkgs (1.91.1 at time of writing)
   - `cargo-steel-lib` is a Steel tool already in PATH via nix profile
   - Output: `~/.local/share/steel/native/libsteel_pty.so`
   - Build takes ~8 min on aarch64

4. **Update `cog.scm`**:
   ```scheme
   (define dylibs '((#:name "steel-pty")))
   ```

5. **Restart Helix** — `:open-term` now works.

### Suggested Action
Keep `scripts/build-steel-pty.sh` in this repo for repeatable builds.
When upgrading Helix/Steel, rebuild steel-pty against the new version.

### Metadata
- Source: error
- Related Files: `term.scm`, `cog.scm`, `helix.scm`
- Tags: steel-pty, dylib, nix-shell, cargo-steel-lib, aarch64
- ABI Note: steel-pty `Cargo.toml` pins `steel-core = "0.8.2"` — must
  match the steel-core version embedded in the Helix binary.

### Resolution
- **Resolved**: 2026-03-19T19:54:00+08:00
- **Notes**: Built successfully via nix-shell; no permanent Rust install
  required. Created `scripts/build-steel-pty.sh` for future rebuilds.

---

## [LRN-20260319-002] knowledge_gap

**Logged**: 2026-03-19T19:54:00+08:00
**Priority**: medium
**Status**: promoted

### Summary
Steel dylib search path: `#%require-dylib` looks in
`~/.local/share/steel/native/` (cargo-steel-lib default output) and
`$STEEL_HOME/native/` (nix profile).

### Details
`cargo-steel-lib` automatically copies the built `.so` to
`~/.local/share/steel/native/`. Steel's `#%require-dylib` searches
this path as well as the nix profile path
(`~/.nix-profile/lib/steel/native/`). No manual copying is needed
after a successful `cargo-steel-lib` build.

### Suggested Action
Document this in AGENTS.md for future reference.

### Metadata
- Source: conversation
- Related Files: `term.scm`
- Tags: steel, dylib, search-path
- See Also: LRN-20260319-001

---
