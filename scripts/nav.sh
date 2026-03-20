#!/usr/bin/env bash
# Smart pane/tab/window navigation for Helix.
# Priority: Zellij > terminal emulator panes > window manager
#
# Usage: nav.sh <direction>
#   direction: left | down | up | right

dir="${1:?Usage: nav.sh <direction>}"

wm_switch() {
    # oxwm: super+j = next window, super+k = prev window
    case "$1" in
        right|down) xdotool key --clearmodifiers super+j ;;
        left|up)    xdotool key --clearmodifiers super+k ;;
    esac
}

if [ -n "$ZELLIJ" ]; then
    zellij ac move-focus-or-tab "$dir" >/dev/null 2>&1

elif [ -n "$KITTY_PID" ]; then
    case "$dir" in
        left)  kitty @ focus-window --match neighbor:left  2>/dev/null || kitty @ focus-tab --match index:-1 ;;
        right) kitty @ focus-window --match neighbor:right 2>/dev/null || kitty @ focus-tab --match index:+1 ;;
        up)    kitty @ focus-window --match neighbor:top    ;;
        down)  kitty @ focus-window --match neighbor:bottom ;;
    esac

elif [ -n "$WEZTERM_PANE" ]; then
    case "$dir" in
        left)  wezterm cli activate-pane-direction Left  2>/dev/null || wezterm cli activate-tab --tab-relative=-1 ;;
        right) wezterm cli activate-pane-direction Right 2>/dev/null || wezterm cli activate-tab --tab-relative=1  ;;
        up)    wezterm cli activate-pane-direction Up    ;;
        down)  wezterm cli activate-pane-direction Down  ;;
    esac

elif [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
    case "$dir" in
        left)  xdotool key --clearmodifiers ctrl+shift+Left  ;;
        right) xdotool key --clearmodifiers ctrl+shift+Right ;;
        up)    xdotool key --clearmodifiers ctrl+shift+Up    ;;
        down)  xdotool key --clearmodifiers ctrl+shift+Down  ;;
    esac

elif [ -n "$RIO_CONFIG" ] || [ "$TERM_PROGRAM" = "rio" ]; then
    case "$dir" in
        left)  xdotool key --clearmodifiers ctrl+shift+bracketleft  ;;
        right) xdotool key --clearmodifiers ctrl+shift+bracketright ;;
        up)    xdotool key --clearmodifiers ctrl+shift+bracketleft  ;;
        down)  xdotool key --clearmodifiers ctrl+shift+bracketright ;;
    esac

else
    wm_switch "$dir"
fi
