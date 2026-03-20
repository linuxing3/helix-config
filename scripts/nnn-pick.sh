#!/bin/sh
tmp=/tmp/hx-nnn-pick
rm -f "$tmp"
start_dir="$(dirname "$1" 2>/dev/null)"
[ -d "$start_dir" ] || start_dir="."
nnn -p "$tmp" "$start_dir" </dev/tty >/dev/tty 2>/dev/tty
[ -f "$tmp" ] && cat "$tmp"
