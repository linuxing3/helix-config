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

## [ERR-20260320-001] string-split FreeIdentifier

**Logged**: 2026-03-20T00:00:00+08:00
**Priority**: medium
**Status**: resolved

### Summary
`projects.scm:27` — `string-split` 不存在导致 `FreeIdentifier` 错误。

### Error
```
error[E02]: FreeIdentifier
  projects.scm:27:22
  Cannot reference an identifier before its definition: string-split
```

### Context
- Steel 没有 `string-split`，正确函数名是 `split-many`。

### Resolution
- **Resolved**: 2026-03-20
- **Notes**: 替换为 `(split-many content "\n")`。

---

## [ERR-20260320-002] area ConversionError float

**Logged**: 2026-03-20T08:45:00+08:00
**Priority**: medium
**Status**: resolved

### Summary
`picker.scm:182` — `area` 收到浮点数 `72.0`，期望整数。

### Error
```
error[E07]: ConversionError
  picker.scm:182:6
  area: Expected number, found: 72.0
```

### Context
- `round` 在 Steel 中返回浮点数，`area` 构造函数要求整数。
- 需用 `(exact (round ...))` 转换。

### Resolution
- **Resolved**: 2026-03-20
- **Notes**: 所有传给 `area` 的 `round` 调用都包上 `exact`。

---

## [ERR-20260320-003] picker flash-close on F5

**Logged**: 2026-03-20T08:30:00+08:00
**Priority**: medium
**Status**: resolved

### Summary
按 F5 打开项目选择器后立即闪退关闭。

### Error
无报错，但 picker 一闪而过。

### Context
- F5 绑定 `:project-switch`，打开 picker 后 Helix 将 F5 key event 传给 picker。
- F5 的 `key-event-char` 返回非 `char?` 值，落入 `else` 分支。
- `else` 分支执行 `pop-last-component!` 关闭 picker。

### Resolution
- **Resolved**: 2026-03-20
- **Notes**: `else` 分支改为 `event-result/consume`。

---

## [ERR-20260320-004] pipe-to ime-switch inserts text

**Logged**: 2026-03-20T12:00:00+08:00
**Priority**: high
**Status**: resolved

### Summary
从 zellij cursor+nnn 窗口切回 helix 时，错误信息被插入到当前编辑文件中。

### Error
随机文本（如 fcitx-remote 的状态数字 `1` 或 `2`，或错误信息）被插入到编辑器光标位置。

### Context
- `config.toml` 中 `ime-switch` 使用 `:pipe-to` 调用。
- `:pipe-to` 会将当前选区作为 stdin，然后用命令的 **stdout 替换选区**。
- `ime-switch` 脚本调用 `fcitx-remote` 输出状态数字到 stdout，这些输出通过 `:pipe-to` 被写入文件。
- `nav.sh` 中 `zellij ac` 的 stderr 也未抑制。
- 窗口切换时可能触发按键事件，导致这些命令意外执行。

### Root Cause
1. `ime-switch` 不需要选区内容，不应使用 `:pipe-to`（应使用 `:sh`）。
2. `fcitx_get`（`fcitx-remote`）的 stdout 未被抑制。
3. `nav.sh` 中 `zellij ac` 的 stderr 未重定向。

### Resolution
- **Resolved**: 2026-03-20
- **Notes**:
  - 所有 `ime-switch` 调用从 `:pipe-to` 改为 `:sh ... >/dev/null 2>&1`。
  - `nav.sh` 中 `zellij ac` 加 `>/dev/null 2>&1`。
  - `config.toml` 中 `zellij ac` 相关 `:sh` 调用都加输出抑制。
  - `st -e zellij` 加 `>/dev/null 2>&1 &` 后台运行。

---
