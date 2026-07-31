import QtQuick
import "../core/theme"

// Non-visual regression check for NebulaThemeLoader (Phase 2.0.5, see
// docs/ThemeLoader.md) — exercises the 5 scenarios its validation
// strategy must survive without crashing: valid theme, unknown token,
// missing token, empty file, invalid value. Run with
// `QML_XHR_ALLOW_FILE_READ=1 qml6 tests/ThemeLoaderHarness.qml`.
QtObject {
    id: root

    property NebulaThemeLoader validLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("fixtures/valid-theme.conf")
    }
    property NebulaThemeLoader unknownTokenLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("fixtures/unknown-token.conf")
    }
    property NebulaThemeLoader missingTokenLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("fixtures/missing-token.conf")
    }
    property NebulaThemeLoader emptyFileLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("fixtures/empty.conf")
    }
    property NebulaThemeLoader invalidValueLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("fixtures/invalid-value.conf")
    }

    property int _failures: 0

    function check(label, condition, detail) {
        if (condition) {
            console.log("PASS:", label)
        } else {
            console.error("FAIL:", label, "--", detail)
            root._failures++
        }
    }

    Component.onCompleted: {
        console.log("=== 1. Valid theme ===")
        check("loaded", validLoader.loaded, validLoader.loadError)
        check("loadError empty", validLoader.loadError.length === 0, validLoader.loadError)
        check("primaryColor applied", validLoader.config.colors.primaryColor.toString() === "#4a90d9",
            validLoader.config.colors.primaryColor.toString())

        console.log("=== 2. Unknown token (surfaceGlassBlur) ===")
        check("still loaded despite unknown token", unknownTokenLoader.loaded, unknownTokenLoader.loadError)
        check("known token still applied", unknownTokenLoader.config.colors.primaryColor.toString() === "#123456",
            unknownTokenLoader.config.colors.primaryColor.toString())

        console.log("=== 3. Missing token (only primaryColor defined) ===")
        check("loaded", missingTokenLoader.loaded, missingTokenLoader.loadError)
        check("defined token applied", missingTokenLoader.config.colors.primaryColor.toString() === "#123456",
            missingTokenLoader.config.colors.primaryColor.toString())
        check("undefined token keeps Core default", missingTokenLoader.config.colors.secondaryColor.toString() === "#6c7a89",
            missingTokenLoader.config.colors.secondaryColor.toString())

        console.log("=== 4. Empty file ===")
        check("not loaded", !emptyFileLoader.loaded, "expected loaded === false")
        check("loadError set", emptyFileLoader.loadError.length > 0, "expected a non-empty loadError")
        check("config keeps Core default", emptyFileLoader.config.colors.primaryColor.toString() === "#4a90d9",
            emptyFileLoader.config.colors.primaryColor.toString())

        console.log("=== 5. Invalid value (bad color, bad number, one valid token) ===")
        check("still loaded (file itself was readable)", invalidValueLoader.loaded, invalidValueLoader.loadError)
        check("invalid color reverted to Core default", invalidValueLoader.config.colors.primaryColor.toString() === "#4a90d9",
            invalidValueLoader.config.colors.primaryColor.toString())
        check("invalid number reverted to Core default", invalidValueLoader.config.spacing.spacingMd === 16,
            invalidValueLoader.config.spacing.spacingMd.toString())
        check("valid token in same file still applied", invalidValueLoader.config.colors.accentColor.toString() === "#00ff00",
            invalidValueLoader.config.colors.accentColor.toString())

        console.log("===")
        if (root._failures === 0) {
            console.log("ThemeLoaderHarness: ALL PASS")
            Qt.exit(0)
        } else {
            console.error("ThemeLoaderHarness:", root._failures, "failure(s)")
            Qt.exit(1)
        }
    }
}
