#!/usr/bin/env bash
# Static structural validator for a Nebula theme against the contract in
# docs/Theme-SDK.md (Phase 2.0, see docs/Roadmap.md). Does not launch
# anything — for that, see the still-unimplemented scripts/test-theme.sh
# (docs/Development-Environment.md §4), or tests/ThemeHarness.qml to
# actually load and visualize a theme's tokens.
#
# Usage: scripts/check-theme.sh <ThemeName>
#   ThemeName   a directory under themes/ (e.g. "template", "nord")

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ThemeName>" >&2
    exit 1
fi

theme_name="$1"
theme_dir="themes/$theme_name"
errors=0

fail() {
    echo "FAIL: $1" >&2
    errors=$((errors + 1))
}

if [ ! -d "$theme_dir" ]; then
    echo "FAIL: $theme_dir does not exist" >&2
    exit 1
fi

echo "== Checking $theme_dir against docs/Theme-SDK.md =="

# --- 1. Required files (Theme-SDK.md §1) ---
for required in README.md metadata.desktop theme.conf Main.qml preview.png; do
    if [ ! -f "$theme_dir/$required" ]; then
        fail "missing required file: $theme_dir/$required"
    fi
done

# --- 2. Reserved asset folders (Theme-SDK.md §3) ---
if [ -d "$theme_dir/assets" ]; then
    for entry in "$theme_dir"/assets/*/; do
        [ -d "$entry" ] || continue
        entry_name=$(basename "$entry")
        case "$entry_name" in
            wallpapers|icons|fonts) ;;
            *) fail "unexpected folder under assets/: $entry_name (reserved: wallpapers, icons, fonts — see Theme-SDK.md §3)" ;;
        esac
    done
fi

if [ -d "$theme_dir/overrides" ]; then
    fail "overrides/ found — not part of the SDK contract, removed by design (see Theme-SDK.md §1)"
fi

# --- 3. theme.conf: only known Design System tokens ---
if [ -f "$theme_dir/theme.conf" ]; then
    # Source of truth: NebulaThemeConfig.qml itself, not a hand-maintained
    # list — stays correct as tokens are added (see docs/Design-Tokens-Reference.md
    # for the human-readable version of the same list).
    known_tokens=$(grep -oP '^\s*(?:readonly\s+)?property\s+(?!QtObject\b)\S+\s+\K\w+(?=:)' core/config/NebulaThemeConfig.qml | grep -v '^valid$')

    in_general=0
    line_num=0
    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))
        trimmed="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$trimmed" ] && continue
        case "$trimmed" in
            \;*|\#*) continue ;;
            \[*\])
                if [ "$trimmed" = "[General]" ]; then in_general=1; else in_general=0; fi
                continue
                ;;
        esac
        [ "$in_general" -eq 1 ] || continue
        key="${trimmed%%=*}"
        if ! echo "$known_tokens" | grep -qx "$key"; then
            fail "$theme_dir/theme.conf:$line_num: unknown token '$key' (not in NebulaThemeConfig — see docs/Design-Tokens-Reference.md)"
        fi
    done < "$theme_dir/theme.conf"
fi

if [ "$errors" -eq 0 ]; then
    echo "PASS: $theme_dir looks structurally sound."
    exit 0
else
    echo "$errors error(s) found in $theme_dir."
    exit 1
fi
