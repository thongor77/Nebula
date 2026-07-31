#!/usr/bin/env bash
# Single entry point to validate the Core's Design System before a commit
# (Phase 1.6, see docs/Roadmap.md). Not a replacement for CI: qmllint runs
# the same way CI does (.github/workflows/qml-lint.yml), but
# VisualHarness.qml and LoginScreenHarness.qml are manual visual harnesses
# (see tests/README.md) — this script opens them for you to eyeball, it
# cannot assert on pixels.
#
# Usage: scripts/check-design-system.sh [--no-visual]
#   --no-visual   skip opening the visual harnesses (qmllint + ThemeSyncCheck only)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

open_visual=1
for arg in "$@"; do
    case "$arg" in
        --no-visual) open_visual=0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

echo "== qmllint (core/, tests/) =="
# Not always on PATH — Arch's qt6-declarative package installs it under
# Qt's own bin directory (`/usr/lib/qt6/bin/qmllint`) rather than
# /usr/bin, unlike some other distros. Found testing a genuinely clean
# install (Milestone 0.1 Beta) — qmake6 -query gives a portable way to
# locate it without hardcoding a distro-specific path.
QMLLINT="$(command -v qmllint || true)"
if [ -z "$QMLLINT" ]; then
    QMAKE="$(command -v qmake6 || command -v qmake || true)"
    if [ -n "$QMAKE" ]; then
        candidate="$("$QMAKE" -query QT_INSTALL_BINS)/qmllint"
        [ -x "$candidate" ] && QMLLINT="$candidate"
    fi
fi
if [ -z "$QMLLINT" ]; then
    echo "qmllint not found on PATH or under Qt's own bin directory." >&2
    echo "Install qt6-declarative (or your distribution's equivalent)." >&2
    exit 1
fi
qml_files=$(find core tests -name "*.qml")
"$QMLLINT" $qml_files
echo "qmllint: PASS"

echo
echo "== ThemeSyncCheck (NebulaThemeConfig / NebulaThemeProvider) =="
qml6 tests/ThemeSyncCheck.qml

if [ "$open_visual" -eq 0 ]; then
    echo
    echo "== Visual harnesses skipped (--no-visual) =="
    exit 0
fi

echo
echo "== Visual harnesses (manual inspection — close each window to continue) =="
# Not gated on exit code: these are manual visual harnesses, not
# pass/fail checks (see tests/README.md). Also a real native-Wayland
# constraint found while building this script — closing the window can
# make the qml runtime exit non-zero (SIGTERM-like path), and unlike X11
# there is no xdotool/wmctrl access to a Wayland client's window to test
# this deterministically from a script. `|| true` keeps that irrelevant
# either way.
echo "Opening VisualHarness.qml..."
qml6 tests/VisualHarness.qml || true
echo "Opening LoginScreenHarness.qml..."
qml6 tests/LoginScreenHarness.qml || true

echo
echo "Design System check complete. qmllint and ThemeSyncCheck passed automatically;"
echo "confirm the two harnesses looked correct by eye before committing."
