#!/usr/bin/env bash
# Removes what scripts/install-nebula.sh installed — never touches
# anything else. See docs/Deployment-Decision.md.
#
# Usage:
#   sudo scripts/uninstall-nebula.sh <ThemeName>   remove one theme only
#   sudo scripts/uninstall-nebula.sh --core         remove the Nebula Core module only
#   sudo scripts/uninstall-nebula.sh --all          remove the Core module and every theme it installed
#
# Safety: a theme directory under /usr/share/sddm/themes/ is only ever
# removed if it contains the `.nebula-managed` marker install-nebula.sh
# writes — a same-named theme installed some other way is left alone.

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ThemeName> | --core | --all" >&2
    exit 1
fi
ARG="$1"

if [ "$EUID" -ne 0 ]; then
    echo "This script removes system paths and must run as root. Try: sudo $0 $ARG" >&2
    exit 1
fi

QMAKE="$(command -v qmake6 || command -v qmake || true)"
if [ -z "$QMAKE" ]; then
    echo "Neither qmake6 nor qmake found — cannot locate Qt's QML install path." >&2
    exit 1
fi
QML_INSTALL_PATH="$("$QMAKE" -query QT_INSTALL_QML)"
NEBULA_MODULE_DIR="$QML_INSTALL_PATH/Nebula"

remove_theme() {
    local theme_dir="/usr/share/sddm/themes/$1"
    if [ ! -d "$theme_dir" ]; then
        echo "'$1' is not installed (no $theme_dir) — nothing to do."
        return 0
    fi
    if [ ! -f "$theme_dir/.nebula-managed" ]; then
        echo "Refusing to remove $theme_dir — no .nebula-managed marker," >&2
        echo "meaning it wasn't installed by scripts/install-nebula.sh." >&2
        return 1
    fi
    rm -rf "$theme_dir"
    echo "Removed theme '$1' ($theme_dir)."
}

remove_core() {
    if [ ! -f "$NEBULA_MODULE_DIR/.nebula-install-info" ]; then
        echo "Nebula Core module not found at $NEBULA_MODULE_DIR (or not installed by install-nebula.sh) — nothing to do."
        return 0
    fi
    rm -rf "$NEBULA_MODULE_DIR"
    echo "Removed Nebula Core module ($NEBULA_MODULE_DIR)."
}

remove_greeter_environment() {
    local conf="/etc/sddm.conf.d/nebula.conf"
    if [ ! -f "$conf" ]; then
        return 0
    fi
    if grep -q "Written by Nebula's install-nebula.sh" "$conf"; then
        rm -f "$conf"
        echo "Removed $conf."
    else
        echo "Leaving $conf in place — doesn't carry Nebula's marker comment," >&2
        echo "meaning it wasn't written by install-nebula.sh." >&2
    fi
}

case "$ARG" in
    --core)
        remove_core
        remove_greeter_environment
        ;;
    --all)
        shopt -s nullglob
        for marker in /usr/share/sddm/themes/*/.nebula-managed; do
            theme_dir="$(dirname "$marker")"
            theme_name="$(basename "$theme_dir")"
            remove_theme "$theme_name"
        done
        remove_core
        remove_greeter_environment
        ;;
    *)
        remove_theme "$ARG"
        ;;
esac
