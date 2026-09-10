#!/usr/bin/env bash
# Verifies a Nebula system installation (scripts/install-nebula.sh) —
# never modifies anything. See docs/Deployment-Decision.md.
#
# Usage: scripts/check-installation.sh [ThemeName]
#   ThemeName   optional — also check this specific installed theme.
#               Without it, only the Core module is checked plus a list
#               of every theme currently installed by Nebula.

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
errors=0

QMAKE="$(nebula_find_qmake)"
if [ -z "$QMAKE" ]; then
    fail "neither qmake6 nor qmake found — cannot locate Qt's QML install path"
    exit 1
fi
QML_INSTALL_PATH="$("$QMAKE" -query QT_INSTALL_QML)"
NEBULA_MODULE_DIR="$QML_INSTALL_PATH/Nebula"
PLATFORM_MODULE_DIR="$NEBULA_MODULE_DIR/Platform/Sddm"

echo "== Core module ($NEBULA_MODULE_DIR) =="

if [ -d "$NEBULA_MODULE_DIR" ]; then
    pass "directory present"
else
    fail "directory missing — run scripts/install-nebula.sh"
fi

if [ -f "$NEBULA_MODULE_DIR/qmldir" ]; then
    type_count=$(grep -cE '^\w+ [0-9]' "$NEBULA_MODULE_DIR/qmldir" 2>/dev/null || echo 0)
    pass "qmldir present ($type_count type(s) declared)"
else
    fail "qmldir missing under $NEBULA_MODULE_DIR"
fi

if [ -f "$PLATFORM_MODULE_DIR/qmldir" ]; then
    pass "Nebula.Platform.Sddm sub-module present"
else
    fail "Nebula.Platform.Sddm sub-module missing (expected at $PLATFORM_MODULE_DIR)"
fi

if [ -f "$NEBULA_MODULE_DIR/.nebula-install-info" ]; then
    echo "-- Installed version --"
    sed 's/^/  /' "$NEBULA_MODULE_DIR/.nebula-install-info"
else
    fail "no .nebula-install-info — version unknown (installed by an older/different method?)"
fi

echo
echo "== Module accessibility (real qml6 load, not just file presence) =="

if command -v qml6 > /dev/null || command -v qml > /dev/null; then
    QML_BIN="$(command -v qml6 || command -v qml)"
    smoke_test_file="$(mktemp --suffix=.qml)"
    trap 'rm -f "$smoke_test_file"' EXIT
    cat > "$smoke_test_file" << 'EOF'
import QtQuick
import Nebula
import Nebula.Platform.Sddm
QtObject {
    property NebulaThemeConfig probe: NebulaThemeConfig {}
    property SDDMUserAdapter probeAdapter: SDDMUserAdapter {}
    Component.onCompleted: Qt.quit()
}
EOF
    # Capture output AND exit code separately — a crashed/aborted
    # process (e.g. no display available, see Development-Environment.md
    # §headless testing) can print nothing to stdout/stderr at all
    # (the "Aborted (core dumped)" notice comes from the invoking
    # shell, not the process itself), which previously made this check
    # report a false PASS purely because $smoke_output was empty,
    # regardless of the real exit code (found testing on a genuinely
    # clean machine, Milestone 0.1 Beta — see Development-Journal.md).
    smoke_output="$("$QML_BIN" "$smoke_test_file" 2>&1)"
    smoke_exit=$?
    if echo "$smoke_output" | grep -q "is not installed"; then
        fail "import Nebula / Nebula.Platform.Sddm failed — module not resolvable by the QML engine:"
        echo "$smoke_output" | sed 's/^/  /' >&2
    elif [ "$smoke_exit" -ne 0 ]; then
        fail "the load test process exited abnormally (exit $smoke_exit) — possibly no display available (try QT_QPA_PLATFORM=offscreen) or a real crash:"
        [ -n "$smoke_output" ] && echo "$smoke_output" | sed 's/^/  /' >&2
    elif [ -n "$smoke_output" ]; then
        fail "unexpected output while loading the module:"
        echo "$smoke_output" | sed 's/^/  /' >&2
    else
        pass "import Nebula and import Nebula.Platform.Sddm both resolve and instantiate cleanly"
    fi
else
    fail "no qml6/qml binary found — cannot run the real load test"
fi

echo
echo "== GreeterEnvironment (QML_XHR_ALLOW_FILE_READ, see DT-0023) =="

NEBULA_SDDM_CONF="/etc/sddm.conf.d/nebula.conf"
if [ -f "$NEBULA_SDDM_CONF" ] && grep -q "GreeterEnvironment=.*QML_XHR_ALLOW_FILE_READ=1" "$NEBULA_SDDM_CONF"; then
    pass "$NEBULA_SDDM_CONF sets QML_XHR_ALLOW_FILE_READ=1"
else
    fail "$NEBULA_SDDM_CONF missing or doesn't set QML_XHR_ALLOW_FILE_READ=1 — every theme's theme.conf will silently fail to load and fall back to Core defaults (see DT-0023)"
fi

echo
echo "== Installed themes (/usr/share/sddm/themes/*/.nebula-managed) =="

found_any=0
shopt -s nullglob
for marker in /usr/share/sddm/themes/*/.nebula-managed; do
    found_any=1
    theme_dir="$(dirname "$marker")"
    theme_name="$(basename "$theme_dir")"
    echo "-- $theme_name ($theme_dir) --"
    if [ -f "$theme_dir/Main.qml" ] && [ -f "$theme_dir/theme.conf" ] && [ -f "$theme_dir/metadata.desktop" ]; then
        pass "  required files present"
    else
        fail "  missing Main.qml/theme.conf/metadata.desktop under $theme_dir"
    fi
    sed 's/^/  /' "$marker"
done
if [ "$found_any" -eq 0 ]; then
    echo "(none found)"
fi

if [ -n "${1:-}" ]; then
    echo
    echo "== Requested theme: $1 =="
    if [ -f "/usr/share/sddm/themes/$1/.nebula-managed" ]; then
        pass "'$1' is installed and Nebula-managed"
    else
        fail "'$1' is not installed (or not Nebula-managed) at /usr/share/sddm/themes/$1"
    fi
fi

echo
if [ "$errors" -eq 0 ]; then
    echo "Installation looks healthy."
    exit 0
else
    echo "$errors problem(s) found."
    exit 1
fi
