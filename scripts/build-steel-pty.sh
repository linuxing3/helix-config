#!/usr/bin/env bash
# Build steel-pty native dylib using nix-shell for the Rust toolchain.
# Output: ~/.local/share/steel/native/libsteel_pty.so
set -euo pipefail

REPO_URL="https://github.com/mattwparas/steel-pty.git"
BUILD_DIR="${TMPDIR:-/tmp}/steel-pty"

# Ensure cargo uses git CLI (avoids SSH auth issues with GitHub deps)
mkdir -p ~/.cargo
if ! grep -q 'git-fetch-with-cli' ~/.cargo/config.toml 2>/dev/null; then
    printf '\n[net]\ngit-fetch-with-cli = true\n' >> ~/.cargo/config.toml
    echo "Added git-fetch-with-cli to ~/.cargo/config.toml"
fi

# Clone or update
if [ -d "$BUILD_DIR/.git" ]; then
    echo "Updating existing clone in $BUILD_DIR ..."
    git -C "$BUILD_DIR" pull --ff-only
else
    echo "Cloning steel-pty to $BUILD_DIR ..."
    rm -rf "$BUILD_DIR"
    git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
fi

echo "Building steel-pty (this takes ~8 min on aarch64) ..."
cd "$BUILD_DIR"
nix-shell -p rustc cargo pkg-config git openssl openssl.dev \
    --run "cargo-steel-lib"

echo ""
echo "Done! libsteel_pty.so installed to ~/.local/share/steel/native/"
echo "Restart Helix for :open-term to work."
