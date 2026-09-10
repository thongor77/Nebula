#!/usr/bin/env bash
# Installs Nebula's Core as a real QML module (Solution B, see
# docs/Deployment-Decision.md and DT-0022 in docs/Decisions-Techniques.md)
# plus one theme. Requires root: writes to Qt's own QML install path
# (found dynamically via qmake, not hardcoded — see
# docs/Development-Journal.md for why) and to /usr/share/sddm/themes/.
#
# Usage: sudo scripts/install-nebula.sh <ThemeName>
#   ThemeName   a directory under themes/ (e.g. "nord", "template")
#
# Idempotent: safe to re-run (each run fully regenerates the Nebula
# module and the requested theme's installed copy, rather than patching
# an existing install).

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ThemeName>" >&2
    exit 1
fi
THEME="$1"

if [ "$EUID" -ne 0 ]; then
    echo "This script writes to system paths (Qt's QML install path," >&2
    echo "/usr/share/sddm/themes/) and must run as root. Try: sudo $0 $THEME" >&2
    exit 1
fi

if [ ! -d "$REPO_ROOT/themes/$THEME" ]; then
    echo "Unknown theme: '$THEME' (no such directory under $REPO_ROOT/themes/)" >&2
    exit 1
fi

QMAKE="$(nebula_find_qmake)"
if [ -z "$QMAKE" ]; then
    echo "Neither qmake6 nor qmake found — cannot locate Qt's QML install path." >&2
    echo "Install qt6-base (or your distribution's equivalent) first." >&2
    exit 1
fi
QML_INSTALL_PATH="$("$QMAKE" -query QT_INSTALL_QML)"
if [ -z "$QML_INSTALL_PATH" ] || [ ! -d "$QML_INSTALL_PATH" ]; then
    echo "'$QMAKE -query QT_INSTALL_QML' did not return a usable path." >&2
    exit 1
fi

NEBULA_MODULE_DIR="$QML_INSTALL_PATH/Nebula"
PLATFORM_MODULE_DIR="$NEBULA_MODULE_DIR/Platform/Sddm"
THEME_INSTALL_DIR="/usr/share/sddm/themes/$THEME"

echo "== Installing Nebula Core module -> $NEBULA_MODULE_DIR =="

# Regenerated fully each run rather than patched in place — simplest way
# to stay idempotent and never leave a stale type behind after a Core
# component is renamed or removed.
rm -rf "$NEBULA_MODULE_DIR"
mkdir -p "$NEBULA_MODULE_DIR"

core_files=$(find "$REPO_ROOT/core" -name "*.qml" | sort)
if [ -z "$core_files" ]; then
    echo "No .qml files found under $REPO_ROOT/core — nothing to install." >&2
    exit 1
fi

: > "$NEBULA_MODULE_DIR/qmldir"
echo "module Nebula" >> "$NEBULA_MODULE_DIR/qmldir"
for f in $core_files; do
    name="$(basename "$f" .qml)"
    cp "$f" "$NEBULA_MODULE_DIR/$name.qml"
    # Same-module siblings resolve without an import statement — internal
    # `import "../X"` lines (config/theme/components/layouts/services)
    # would otherwise reference directories that no longer exist in the
    # flattened module (verified in the Phase 2.2 prototype, see
    # docs/Development-Journal.md).
    sed -i '/^import "\.\.\//d' "$NEBULA_MODULE_DIR/$name.qml"
    echo "$name 1.0 $name.qml" >> "$NEBULA_MODULE_DIR/qmldir"
done
echo "  $(echo "$core_files" | wc -l) type(s) installed."

echo "== Installing Nebula.Platform.Sddm module -> $PLATFORM_MODULE_DIR =="

rm -rf "$PLATFORM_MODULE_DIR"
mkdir -p "$PLATFORM_MODULE_DIR"

platform_files=$(find "$REPO_ROOT/platform/sddm" -name "*.qml" | sort)
: > "$PLATFORM_MODULE_DIR/qmldir"
echo "module Nebula.Platform.Sddm" >> "$PLATFORM_MODULE_DIR/qmldir"
for f in $platform_files; do
    name="$(basename "$f" .qml)"
    cp "$f" "$PLATFORM_MODULE_DIR/$name.qml"
    echo "$name 1.0 $name.qml" >> "$PLATFORM_MODULE_DIR/qmldir"
done
echo "  $(echo "$platform_files" | wc -l) adapter(s) installed."

# Version marker — read back by scripts/check-installation.sh. Uses the
# repo's own commit when available (this script is normally run from a
# git checkout); falls back to a timestamp otherwise so the file is never
# absent.
if git -C "$REPO_ROOT" rev-parse HEAD > /dev/null 2>&1; then
    installed_from="git $(git -C "$REPO_ROOT" rev-parse --short HEAD)"
else
    installed_from="unknown (no git metadata at install time)"
fi
printf 'installed_from=%s\ninstalled_at=%s\n' "$installed_from" "$(date -Iseconds)" \
    > "$NEBULA_MODULE_DIR/.nebula-install-info"

# NebulaThemeLoader reads theme.conf via XMLHttpRequest, deliberately —
# see docs/ThemeLoader.md §3 — rather than SDDM's own `config.<key>`
# context property, to keep Core decoupled from SDDM (Nebula-Principles.md
# §2). Qt6 blocks local-file XHR reads by default; without this, every
# theme's theme.conf silently fails to load and NebulaThemeConfig falls
# back to its hardcoded defaults instead — no crash, no visible error,
# just the wrong colors (discovered during Phase 3.0, see DT-0023).
# GreeterEnvironment= is SDDM's own supported mechanism for setting
# environment variables for the greeter process (confirmed present in
# the installed sddm binary — see docs/Compatibility-Matrix.md).
echo "== Configuring GreeterEnvironment (QML_XHR_ALLOW_FILE_READ) =="

SDDM_CONF_D="/etc/sddm.conf.d"
NEBULA_SDDM_CONF="$SDDM_CONF_D/nebula.conf"
mkdir -p "$SDDM_CONF_D"
cat > "$NEBULA_SDDM_CONF" << 'EOF'
# Written by Nebula's install-nebula.sh — safe to remove, Nebula will
# regenerate it on the next install. See docs/Decisions-Techniques.md
# (DT-0023) for why this is required.
[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1
EOF
echo "  wrote $NEBULA_SDDM_CONF"

echo "== Installing theme '$THEME' -> $THEME_INSTALL_DIR =="

rm -rf "$THEME_INSTALL_DIR"
mkdir -p "$THEME_INSTALL_DIR"
cp -r "$REPO_ROOT/themes/$THEME/." "$THEME_INSTALL_DIR/"

# Rewrite the installed copy's imports to the module form — the repo's
# own Main.qml keeps ordinary relative imports unchanged (dev/test
# workflow via qml6/sddm-greeter --test-mode --theme themes/<name> stays
# exactly as documented in Creating-A-Theme.md); only the installed
# artifact is transformed. See docs/Deployment-Decision.md for why this
# split was chosen over renaming core/ itself.
sed -i \
    -e 's#import "\.\./\.\./core/[a-zA-Z]*"#import Nebula#g' \
    -e 's#import "\.\./\.\./platform/sddm"#import Nebula.Platform.Sddm#g' \
    "$THEME_INSTALL_DIR/Main.qml"
# A theme may have imported several core/ subdirectories (theme, config,
# components, layouts, services) as separate lines, all collapsing to the
# same `import Nebula` — de-duplicate so qmllint/the engine don't see the
# same import repeated.
awk '!(/^import Nebula$/ && seen++)' "$THEME_INSTALL_DIR/Main.qml" > "$THEME_INSTALL_DIR/Main.qml.tmp"
mv "$THEME_INSTALL_DIR/Main.qml.tmp" "$THEME_INSTALL_DIR/Main.qml"

# Marker read back by scripts/uninstall-nebula.sh before deleting anything
# under /usr/share/sddm/themes/ — makes sure it only ever removes a
# directory Nebula itself installed, never a same-named theme a user
# installed some other way.
printf 'source_theme=%s\ninstalled_from=%s\ninstalled_at=%s\n' \
    "$THEME" "$installed_from" "$(date -Iseconds)" \
    > "$THEME_INSTALL_DIR/.nebula-managed"

echo
echo "Done. Verify with: scripts/check-installation.sh $THEME"
