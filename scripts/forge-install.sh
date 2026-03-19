#!/usr/bin/env bash
# Wrapper around `forge install` that temporarily hides .direnv to work around
# a Steel/libgit2 bug: copy-directory-recursively! crashes on symlinks pointing
# to directories (common in nix-direnv flake-inputs).
set -euo pipefail

cd "$(dirname "$0")/.."
HELIX_DIR="$(pwd)"
TMPDIR="${TMPDIR:-/tmp}"
DIRENV_BAK="$TMPDIR/.direnv_forge_bak_$$"

cleanup() {
    if [ -d "$DIRENV_BAK" ]; then
        mv "$DIRENV_BAK" "$HELIX_DIR/.direnv"
    fi
}
trap cleanup EXIT

if [ -d .direnv ]; then
    mv .direnv "$DIRENV_BAK"
fi

forge install "$@"
