import QtQuick
import "../core/config"
import "../core/theme"

// Non-visual regression check: verifies every design-token group defined
// in NebulaThemeConfig is actually re-exposed by NebulaThemeProvider —
// the exact regression found in Phase 1.5 (overlay/surface tokens
// defined in NebulaThemeConfig but never wired into NebulaThemeProvider,
// see docs/Development-Journal.md). Run with
// `qml6 tests/ThemeSyncCheck.qml`; exits non-zero and logs any missing
// group on failure, nothing rendered on screen.
Item {
    id: root

    property NebulaThemeConfig config: NebulaThemeConfig {}
    property NebulaThemeProvider provider: NebulaThemeProvider {}

    function tokenGroups(obj) {
        return Object.keys(obj).filter((key) => {
            return typeof obj[key] === "object" && obj[key] !== null
        })
    }

    Component.onCompleted: {
        var configGroups = tokenGroups(config)
        var providerGroups = tokenGroups(provider)
        var missing = configGroups.filter((g) => providerGroups.indexOf(g) === -1)

        if (missing.length > 0) {
            console.error("ThemeSyncCheck: FAIL - token group(s) defined in NebulaThemeConfig but not exposed by NebulaThemeProvider:", missing.join(", "))
            Qt.exit(1)
        } else {
            console.log("ThemeSyncCheck: PASS -", configGroups.length, "token group(s) all exposed by NebulaThemeProvider (" + configGroups.join(", ") + ")")
            Qt.exit(0)
        }
    }
}
