# Helix 编辑器配置

基于 [Helix](https://helix-editor.com/) 编辑器的个人配置，集成了
[Steel](https://github.com/mattwparas/steel) 插件系统（Scheme 脚本）、
Zellix 工作流以及 Vim 操作模拟。

## 概述

本仓库包含在 **UOS（aarch64-linux）** 系统上运行深度定制 Helix 所需的全部
配置，配合 Zellij 终端复用器使用。

### 核心特性

- **Steel 插件系统** — 通过 `.scm` 文件实现 Scheme 脚本扩展
- **内嵌终端** — 基于 PTY 的编辑器内终端（`term.scm`）
- **Vim 操作模拟** — 完整的 `d`、`c`、`y`、`f/t`、可视行等操作（`vim/`）
- **文件树** — 侧边栏文件浏览器（`cogs/file-tree.scm`）
- **最近文件选择器** — 自动快照与快速打开（`cogs/recentf.scm`）
- **Git 状态选择器** — 编辑器内 git 状态查看（`cogs/git-status-picker.scm`）
- **启动画面** — 启动时显示 ASCII 艺术与快捷提示（`splash.scm`）
- **专注模式** — 裁剪左右边距实现无干扰编辑（`focus.scm`）
- **Scheme 缩进** — S-expression 智能缩进（`cogs/scheme-indent.scm`）
- **Spacemacs 主题** — 移植的 Spacemacs 配色方案（`cogs/themes/spacemacs.scm`）
- **Zellix 工作流** — NuShell 驱动的 Helix + Zellij 集成（yazi、lazygit、项目切换等）
- **Nix 开发环境** — `flake.nix` + direnv 实现可复现的工具链

## 目录结构

```
~/.config/helix/
├── config.toml          # 核心配置（主题、快捷键、LSP 等）
├── languages.toml       # 语言服务器与格式化器定义
├── init.scm             # Steel 入口 — 加载包、设置主题和快捷键
├── helix.scm            # Steel 核心库 — eval、git、shell、minor mode 宏
├── keymaps.scm          # init.scm 加载的键位映射辅助模块
├── cog.scm              # Steel 包清单（依赖声明）
├── splash.scm           # 启动画面组件
├── focus.scm            # 专注/禅模式组件
├── term.scm             # 内嵌终端（需要 steel-pty 动态库）
│
├── cogs/                # 插件模块（git submodule: mattwparas/helix-config）
│   ├── package.scm      #   包加载器与注册表
│   ├── keymaps.scm      #   键位映射合并/复制工具与 DSL
│   ├── file-tree.scm    #   文件树侧边栏
│   ├── recentf.scm      #   最近文件选择器（后台自动快照）
│   ├── git-status-picker.scm  # Git 状态集成选择器
│   ├── scheme-indent.scm      # S-expression 智能缩进
│   ├── helix-ext.scm    #   扩展 eval/prompt 命令
│   ├── picker.scm       #   通用选择器组件
│   ├── labelled-buffers.scm   # 命名缓冲区管理
│   └── themes/spacemacs.scm   # Spacemacs 主题
│
├── vim/                 # Vim 操作模拟层
│   ├── init.scm         #   Vim 键位映射引导
│   ├── utils.scm        #   共享工具函数
│   ├── normal-motions.scm   # 普通模式动作
│   ├── visual-motions.scm   # 可视模式动作
│   ├── delete-motions.scm   # d 前缀删除动作
│   ├── change-motions.scm   # c 前缀修改动作
│   ├── yank-motions.scm     # y 前缀复制动作
│   └── key-emulation.scm   # 按键转换辅助
│
├── icons/nerd.toml      # Nerd Font 图标映射
├── actions/             # 各语言编辑器动作配置（cpp、go、lua、rust、markdown）
├── snippets/            # 代码片段（cpp、go、js、markdown、nix、reactjs）
├── scripts/             # 辅助脚本（hx-ala、hx-desktop、ime-switch 等）
├── doc/                 # 参考文档（language-server.md、deno languages.toml）
├── tests/               # 动作模板测试源文件
├── tutors/              # 教程内容（中文）
│
├── flake.nix            # Nix flake 开发环境（Node.js / Bun）
├── flake.lock           # Nix flake 锁文件
├── .envrc               # direnv 集成（`use flake`）
├── justfile             # Just 任务运行器（nix repl）
└── AGENTS.md            # AI 编码助手指引
```

## Steel 插件系统

本配置使用 **Steel** 脚本引擎——一种内嵌于
[mattwparas](https://github.com/mattwparas/helix) Helix fork 中的 Scheme 方言。

### 入口文件

| 文件 | 作用 |
|------|------|
| `init.scm` | 主入口 — 加载包、设置主题、定义快捷键 |
| `helix.scm` | 核心库 — eval、git 辅助、shell、minor mode 宏 |
| `keymaps.scm` | 从 `cogs.hx/` 加载的备选键位映射 |
| `cog.scm` | 包清单 — 声明 `steel-pty` 和 `helix-file-watcher` 依赖 |

### 加载流程

```
hx 启动
 └─► init.scm
      ├─► require "cogs/keymaps.scm"    （键位映射 DSL）
      ├─► require "helix/commands.scm"   （Helix 命令绑定）
      ├─► require "splash.scm"           （启动画面）
      ├─► require "focus.scm"            （专注模式）
      ├─► recentf-snapshot               （启动最近文件快照）
      ├─► keymap (global) ...            （全局快捷键）
      ├─► define-lsp ...                 （LSP 定义）
      ├─► define-language "scheme" ...   （Scheme 语言配置）
      └─► show-splash                    （显示启动画面）
```

### 包（通过 `load-package` 加载）

| 包 | 说明 |
|----|------|
| `term.scm` | 内嵌 PTY 终端（`:open-term`、`:new-term`、`xplr`） |
| `cogs/file-tree.scm` | 文件树，支持自定义快捷键 |
| `cogs/recentf.scm` | 最近文件选择器，后台自动快照 |
| `cogs/git-status-picker.scm` | Git 状态集成选择器 |
| `cogs/scheme-indent.scm` | Scheme/Lisp 按 `Enter` 时智能缩进 |
| `cogs/helix-ext.scm` | `eval-buffer`、`evalp` 交互求值、线程安全上下文 |

### 安装依赖

```bash
# 安装 forge 命令行工具
cargo install --git https://github.com/mattwparas/steel.git steel-forge

# 安装插件依赖（steel-pty、helix-file-watcher）
forge install
```

## Vim 模拟

`vim/` 目录提供了接近完整的 Vim 操作层：

- **普通模式** — `h/j/k/l`、`w/e/b`、`f/F/t/T`、`G`、`%`、`0/$`
- **可视模式** — `v`、`V`（可视行）、可视块操作
- **操作符** — `d{动作}`、`c{动作}`、`y{动作}`，支持完整的内部/环绕文本对象
- **撤销** — Vim 兼容的撤销行为

启用方法：在 `init.scm` 中添加 `(require "vim/init.scm")`。

## 快捷键说明（config.toml）

### 功能键

| 按键 | 普通模式 | 插入模式 |
|------|----------|----------|
| `F1` | 格式化 | 格式化 |
| `F2` | 重命名符号 | 重命名符号 |
| `F3` | Lazygit（Zellij 浮窗） | Lazygit |
| `F4` | Yazi 文件查找 | Yazi |
| `F5` | Justfile 运行 | Justfile |
| `F6` | 项目切换 | 项目切换 |
| `F7-F10` | DAP 调试 | — |
| `F11` | 跳转到定义 | — |
| `F12` | 跳转到实现 | — |

### 空格菜单（普通模式）

| 前缀 | 按键 | 动作 |
|------|------|------|
| `空格` | `空格` | 命令模式 |
| `空格` | `.` | 当前目录文件选择器 |
| `空格 f` | `y/n/p/t/g` | Yazi / nnn / 项目 / 终端 / ripgrep |
| `空格 b` | `b/n/v/h/c/o` | 缓冲区选择 / 新建 / 垂直分割 / 水平分割 / 关闭 / 仅保留 |
| `空格 c` | `a/r/f/i/s` | 代码动作 / 重命名 / 格式化 / 内联提示 / switcheroo |
| `空格 t` | `a-p` | 主题切换 |
| `空格 l` | `a/h/r/m/j/s/t/g` | AI / home-manager / 重映射 / make / just / sh / 多任务 / tangle |
| `空格 e` | `a/w/f/n/p` | Emacsclient / zk 笔记 / glow 预览 |
| `空格 o` | `g/p/a/t` | 打开标签页：lazygit / ipython / opencode / shell |
| `空格 r` | `p/a/t/1-3/l/h` | 发送选区到标签页 / 浮窗 / 面板 |

### Zellij 集成

| 按键 | 动作 |
|------|------|
| `C-h/j/k/l` | 在 Zellij 面板间移动焦点 |
| `C-A-Esc` | 发送当前行到右侧面板 |
| `C-A-Space` | 发送整行到右侧面板 |
| `C-a + n/h/v/z/m` | 新面板 / 下方分割 / 右侧分割 / 全屏 / neomutt |
| `C-t + n` | 新建标签页 |

### 其他常用快捷键

| 按键 | 动作 |
|------|------|
| `jj`（插入模式） | 回到普通模式 |
| `s` | 保存所有缓冲区 |
| `Z` | 保存并关闭所有 |
| `H / L` | 上/下一个缓冲区 |
| `G` | 跳到文件末尾 |
| `U / D` | 删除到行首 / 行尾 |
| `C-d` | 复制当前行 |
| `C-/` | 切换注释 |
| `C-] / C-[` | 增加 / 减少缩进 |
| `C-r` | 多重选择当前单词 |
| `]] / [[` | 重载配置 / 打开配置文件 |
| `\ + 1-9` | 快速切换工作目录 |

## 语言与格式化器

在 `languages.toml` 中配置：

| 语言 | 格式化器 | LSP |
|------|----------|-----|
| Rust | `rustfmt` | `rust-analyzer` |
| Go | — | `gopls` + `golangci-lint-lsp` |
| Python | `ruff format` | `pylsp` / `ruff` |
| Lua | `stylua` | `lua-language-server` |
| JS/TS | `prettier` | `typescript-language-server` / `vscode-eslint` |
| JSON/JSONC | `prettier` | `vscode-json-language-server` |
| Typst | `typst c` | `typst-lsp` |
| Scheme | `raco fmt` | `steel-language-server` |
| Nix | — | `nil` |

## 前置依赖

- [Helix（Steel fork）](https://github.com/mattwparas/helix) — 通过 `cargo xtask steel` 构建
- [Zellij](https://zellij.dev/) 终端复用器
- [Zellix](https://github.com/user/zellix) NuShell 插件系统（`~/.config/zellix`）
- [Nix](https://nixos.org/) + [direnv](https://direnv.net/)（可选，用于开发环境）
- [steel-pty](https://github.com/mattwparas/steel-pty)（用于内嵌终端）

## 快速开始

```bash
# 1. 克隆配置到 Helix 配置目录
git clone <repo-url> ~/.config/helix

# 2. 初始化 cogs 子模块(可选)
cd ~/.config/helix && git submodule update --init

# 3. 安装 Steel 插件依赖
forge install

# 4. （可选）启用 Nix 开发环境
direnv allow

# 5. 启动 Helix
hx
```

## 许可

个人配置 — 欢迎参考或改编。
