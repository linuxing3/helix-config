# Learnings

## [LRN-20260326-001] bug_fix

**Logged**: 2026-03-26T00:00:00-03:00
**Priority**: high
**Status**: resolved

### Summary
`term.scm` startup commands can lose their first character when sent to a fresh
PTY byte-by-byte.

### Details
`default-on-start-function` opens the embedded terminal by running:

```scheme
(pty-process-run-line! pty (string-append "cd -- " workspace))
(pty-process-run-line! pty "clear")
```

`pty-process-run-line!` previously called `pty-process-type!`, which loops over
the string and writes each character individually via
`pty-process-send-command-char`, then sends `"\r"` separately.

On a newly created PTY this can race with shell startup and drop the first
character of the command, so `cd -- ...` arrives as `d -- ...`.

### Resolution
- Change `pty-process-run-line!` to send the entire command plus trailing
  carriage return in a single `pty-process-send-command` call:
  ```scheme
  (pty-process-send-command pty (string-append text "\r"))
  ```
- Delay bootstrap commands with `enqueue-thread-local-callback-with-delay` so
  `cd`/`clear` and `xplr` are injected after shell startup.
- Run the embedded terminal through a dedicated wrapper that executes
  `/bin/zsh -f -i`, keeping zsh interactive while skipping user rc files, so
  startup hooks like `compinit`, `direnv`, and `direnv allow` prompts cannot
  block the PTY before the bootstrap command runs.
- Keep `pty-process-type!` for interactive character input, but avoid it for
  startup/bootstrap commands.

### Metadata
- Source: debugging
- Related Files: `term.scm`
- Tags: steel-pty, helix, terminal, pty, startup, race-condition

---

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

## [LRN-20260320-001] steel_api

**Logged**: 2026-03-20T08:50:00+08:00
**Priority**: high
**Status**: resolved

### Summary
Steel Scheme 常见 API 陷阱与正确用法（Helix 插件开发）。

### Details

#### 1. `write-line!` vs `display` + `newline` — 字符串序列化陷阱
- `write-line!` 使用 Scheme 的 `write` 语义，输出字符串时会自动加双引号和转义符
  （如 `"/home/foo"` 而不是 `/home/foo`）
- 如果需要写入纯文本文件（如项目路径列表），必须用 `display` + `newline`：
  ```scheme
  (display p out)
  (newline out)
  ```
- `recentf.scm` 用 `write-line!` 写入 + `read!` 读回（S-expression 反序列化），
  是正确的配对用法。但若用 `split-many` 按行分割读回，写入必须用 `display`。

#### 2. `string-split` 不存在，用 `split-many`
- Steel 没有 `string-split` 函数，应使用 `split-many`：
  ```scheme
  (split-many content "\n")
  ```

#### 3. `round` 返回浮点数，`area` 需要整数
- Steel 的 `round` 返回浮点数（如 `72.0`），但 `area` 构造函数要求整数参数。
- 必须用 `exact` 包裹：
  ```scheme
  (exact (round (/ width 2)))
  ```
- 参考 `splash.scm` 中的做法。

#### 4. Picker 组件 — 搜索后必须重置 cursor
- `fuzzy-match` 过滤 `items-view` 后，必须同时重置 `cursor` 和 `window-start`
  为 0，否则 cursor 超出新列表范围，显示不更新。
- 空列表保护：`move-cursor-down`/`move-cursor-up` 中对列表长度为 0 时做
  `modulo` 会除零崩溃，需加 `(when (> items-len 0) ...)` 守卫。

#### 5. Picker 组件 — `else` 分支不应关闭 picker
- `picker-event-handler` 的 `else` 分支原先会 `pop-last-component!` 关闭 picker。
- F5 等功能键的 `key-event-char` 返回非 `char?` 值，落入 `else` 导致 picker
  一闪而过。改为 `event-result/consume` 静默忽略。

#### 6. 文件系统 API
- `read-dir` — 列出目录直接子项（depth 1），返回完整路径列表
- `is-dir?` — 判断路径是否为目录
- `path-exists?` — 判断路径是否存在
- `create-directory!` — 创建目录

#### 7. 提示用户输入 — `prompt`
- 使用 `(prompt "提示文本: " callback)` + `push-component!` 弹出输入框：
  ```scheme
  (push-component!
   (prompt "Enter path: "
    (lambda (input) (do-something input))))
  ```

### Metadata
- Source: conversation (multi-round debugging session)
- Related Files: `cogs/projects.scm`, `cogs/picker.scm`, `splash.scm`
- Tags: steel, api, write-line, split-many, round, exact, picker, prompt

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

## [LRN-20260320-001] best_practice

**Logged**: 2026-03-20T09:10:00+08:00
**Priority**: high
**Status**: resolved

### Summary
在 Helix 中集成 nnn 作为文件选择器需要用 wrapper 脚本，不能像 yazi 那样直接用 `:insert-output`。

### Details
Helix 的 `:insert-output` 会捕获子进程的 stdout。yazi 能直接配合 `:insert-output` 工作是因为 yazi 内部会自动处理 tty。但 nnn 不行——直接用 `:insert-output nnn ... >/dev/tty` 会导致：

1. nnn 无法正常显示 TUI（stdin 未连接到 tty）
2. 随机文件内容被插入到当前 buffer

**解决方案**：创建 wrapper 脚本 `scripts/nnn-pick.sh`，在脚本中将 nnn 的 stdin/stdout/stderr 全部重定向到 `/dev/tty`：

```sh
#!/bin/sh
tmp=/tmp/hx-nnn-pick
rm -f "$tmp"
nnn -p "$tmp" </dev/tty >/dev/tty 2>/dev/tty
[ -f "$tmp" ] && cat "$tmp"
```

配置中用 `:insert-output ~/.config/helix/scripts/nnn-pick.sh` 调用。脚本最后 `cat` 将选中路径输出到 stdout（被 `:insert-output` 捕获），然后 `:open %sh{cat /tmp/hx-nnn-pick}` 打开文件。

**通用规则**：任何需要 tty 交互的 TUI 程序（不像 yazi 那样自动处理 tty），都应该用 wrapper 脚本并显式重定向 `</dev/tty >/dev/tty 2>/dev/tty`。

### Metadata
- Source: conversation
- Related Files: `config.toml`, `scripts/nnn-pick.sh`
- Tags: helix, nnn, tui, file-picker, insert-output, tty
- See Also: yazi chooser-file pattern in config.toml

---
