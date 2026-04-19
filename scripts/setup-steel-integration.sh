#!/usr/bin/env bash
# Bootstrap local Steel runtime paths for this Helix config.
# This does not build native libraries by itself; it prepares the directories,
# symlinks local Scheme cogs, and reports which dylibs are still missing.
set -euo pipefail

HELIX_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STEEL_HOME="${STEEL_HOME:-$HOME/.steel}"
STEEL_COGS_DIR="$STEEL_HOME/cogs"
STEEL_NATIVE_DIR="${STEEL_NATIVE_DIR:-$HOME/.local/share/steel/native}"
FALLBACK_NATIVE_DIR="$STEEL_HOME/native"
NIX_NATIVE_DIR="$HOME/.nix-profile/lib/steel/native"

mkdir -p "$STEEL_COGS_DIR" "$STEEL_NATIVE_DIR" "$FALLBACK_NATIVE_DIR"

link_cog() {
    local source_dir="$1"
    local target_name="$2"
    local target_path="$STEEL_COGS_DIR/$target_name"

    if [ -L "$target_path" ] || [ -e "$target_path" ]; then
        rm -rf "$target_path"
    fi

    ln -s "$source_dir" "$target_path"
    printf 'linked %s -> %s\n' "$target_path" "$source_dir"
}

check_library() {
    local lib="$1"

    if [ -f "$STEEL_NATIVE_DIR/$lib" ]; then
        printf 'found %s in %s\n' "$lib" "$STEEL_NATIVE_DIR"
        return 0
    fi

    if [ -f "$FALLBACK_NATIVE_DIR/$lib" ]; then
        printf 'found %s in %s\n' "$lib" "$FALLBACK_NATIVE_DIR"
        return 0
    fi

    if [ -f "$NIX_NATIVE_DIR/$lib" ]; then
        printf 'found %s in %s\n' "$lib" "$NIX_NATIVE_DIR"
        return 0
    fi

    printf 'missing %s\n' "$lib"
    return 1
}

link_cog "$HELIX_DIR/scooter" "scooter"
link_cog "$HELIX_DIR/streal" "streal"
link_cog "$HELIX_DIR" "mattwparas-helix-package"

printf '\nSteel runtime paths\n'
printf '  STEEL_HOME: %s\n' "$STEEL_HOME"
printf '  native:     %s\n' "$STEEL_NATIVE_DIR"
printf '  fallback:   %s\n' "$FALLBACK_NATIVE_DIR"
printf '  nix:        %s\n' "$NIX_NATIVE_DIR"

missing=0

printf '\nNative library status\n'
check_library "libsteel_pty.so" || missing=1
check_library "libsteel_nrepl.so" || missing=1
check_library "libscooter_hx.so" || missing=1

if [ "$missing" -ne 0 ]; then
    printf '\nNext steps\n'
    printf '  1. Build steel-pty with %s\n' "$HELIX_DIR/scripts/build-steel-pty.sh"
    printf '  2. Install steel-nrepl via the nrepl.hx build in AGENTS.md\n'
    printf '  3. Install or copy libscooter_hx.so as described in AGENTS.md\n'
    printf '  4. Restart Helix after the native libraries are present\n'
else
    printf '\nAll required Steel native libraries were found.\n'
    printf 'Restart Helix and test :open-term, :nrepl-connect, and :scooter.\n'
fi
