#!/usr/bin/env bash
# Shared helpers sourced by install-nebula.sh, uninstall-nebula.sh and
# check-installation.sh. Extracted (Phase 3.3, see
# docs/Architecture-Review-2026.md §6/§9) because the exact same
# qmake6/qmake detection idiom appeared identically in all three — the
# real 3-occurrence threshold this project already uses elsewhere
# before factoring something out. No behavior change intended: every
# caller keeps its own error message wording and error-handling style
# (the "actor" scripts exit immediately on failure, check-installation.sh
# accumulates via fail()/errors) — this file only removes the duplicated
# detection itself.

# Prints the qmake6 (or qmake) binary path found on PATH, or nothing if
# neither exists. Never exits and never prints an error — callers decide
# what "not found" means for them (each already did, and still does).
nebula_find_qmake() {
    command -v qmake6 || command -v qmake || true
}

# fail()/pass() — shared by the two "verifier" scripts
# (check-installation.sh, check-theme.sh), which must accumulate every
# problem found rather than stop at the first one (see scripts/README.md
# for why this differs from the "actor" scripts' set -euo pipefail).
# Callers must declare `errors=0` before the first fail() call — kept as
# a plain caller-owned variable rather than a new naming convention,
# since both scripts already used exactly this name identically before
# this file existed.
fail() {
    echo "FAIL: $1" >&2
    errors=$((errors + 1))
}

pass() {
    echo "PASS: $1"
}
