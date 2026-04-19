# Steel Integration

This Helix config already contains the Scheme entrypoints for Steel:

- `init.scm` loads the local cogs and commands.
- `helix.scm` registers package modules with `load-package`.
- `cog.scm` declares the native dylibs Helix should load:
  `steel-pty`, `steel-nrepl`, and `scooter_hx`.

To make the integration work on a machine, the missing part is the local Steel
runtime layout and the native libraries on disk.

## Bootstrap

Run:

```bash
./scripts/setup-steel-integration.sh
```

That script will:

- create `~/.steel/cogs`, `~/.steel/native`, and `~/.local/share/steel/native`
- symlink this repo's `scooter/` and `streal/` directories into `~/.steel/cogs/`
- symlink this repo as `~/.steel/cogs/mattwparas-helix-package`
- report whether `libsteel_pty.so`, `libsteel_nrepl.so`, and
  `libscooter_hx.so` are currently discoverable

## Required runtime pieces

1. Install a Steel-enabled Helix build.

```bash
cargo xtask steel
```

Per `cogs/README.md`, that installs Helix with Steel support plus `forge`,
`steel-language-server`, and `steel-repl`.

2. Prepare the local Steel cog paths.

```bash
./scripts/setup-steel-integration.sh
```

3. Install or build the native libraries.

- `libsteel_pty.so`:
  run `./scripts/build-steel-pty.sh`
- `libsteel_nrepl.so`:
  follow the `nrepl.hx` build steps in `AGENTS.md`
- `libscooter_hx.so`:
  install `scooter.hx` and ensure the `.so` ends up under
  `~/.local/share/steel/native/` or `~/.steel/native/`

4. Restart Helix and verify:

- `:open-term`
- `:nrepl-connect`
- `:scooter`

## Notes

- `forge install` is still useful for Steel package dependencies, but this repo
  also relies on out-of-tree native builds documented in `AGENTS.md`.
- If Helix reports `dylib not found`, check both `~/.local/share/steel/native/`
  and `~/.steel/native/`.
