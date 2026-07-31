import QtQuick
import "../core/theme"
import "../core/components"

// Standalone theme loader/visualizer — doesn't depend on any particular
// theme (see docs/Theme-SDK.md §6). A thin consumer of NebulaThemeLoader
// (Phase 2.0.5, see docs/ThemeLoader.md) — contains no loading logic of
// its own.
//
// Usage: QML_XHR_ALLOW_FILE_READ=1 qml6 tests/ThemeHarness.qml -- <ThemeName>
//   <ThemeName>  a directory under themes/ (default: "template")
//
// QML_XHR_ALLOW_FILE_READ=1 is required — local file reads via
// XMLHttpRequest are disabled by default in this Qt6 build (see
// docs/ThemeLoader.md).
Item {
    id: root
    width: 640
    height: 720

    property string themeName: {
        var args = Qt.application.arguments
        var sepIndex = args.indexOf("--")
        if (sepIndex !== -1 && args.length > sepIndex + 1) {
            return args[sepIndex + 1]
        }
        return "template"
    }

    property NebulaThemeLoader loader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("../themes/" + root.themeName + "/theme.conf")
    }
    property NebulaThemeProvider theme: NebulaThemeProvider {
        config: root.loader.config
    }

    // Read `loader.loaded`/`loader.loadError` directly rather than the
    // loader's themeLoaded()/themeLoadFailed() signals — both are
    // already correct synchronously by the time this Item finishes
    // constructing, and the signals fired during the loader's own
    // construction wouldn't reach a handler declared here anyway (see
    // docs/Development-Journal.md, Phase 2.0.5).
    property var tokenLines: {
        if (!root.loader.loaded) return []
        var lines = []
        var groupNames = Object.keys(root.theme).filter((key) => {
            return typeof root.theme[key] === "object" && root.theme[key] !== null
                && key !== "config" && key !== "assets"
        })
        for (var i = 0; i < groupNames.length; i++) {
            var group = root.theme[groupNames[i]]
            var tokenNames = Object.keys(group).filter((key) => {
                return key !== "objectName" && typeof group[key] !== "function"
            })
            for (var j = 0; j < tokenNames.length; j++) {
                lines.push(groupNames[i] + "." + tokenNames[j] + " = " + group[tokenNames[j]])
            }
        }
        return lines
    }

    Rectangle {
        // Item has no background of its own — without this, the white
        // Text labels below render invisibly on the default white
        // background (found while testing this harness for real).
        anchors.fill: parent
        color: "#1e1e1e"
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 32
        clip: true

        Column {
            id: content
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 16

            Text {
                text: "ThemeHarness — " + root.themeName
                font.pixelSize: 20
                font.bold: true
                color: "white"
            }

            Text {
                visible: !root.loader.loaded
                text: "FAILED TO LOAD: " + root.loader.loadError
                color: "#d9534f"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Text {
                // Deliberately reads root.themeName, not root.loader.configPath,
                // to display the source path — reading configPath here
                // caused a real binding loop (Qt.BindingLoopDetected),
                // since this Text also depends on tokenLines, which is
                // itself only populated by reload(), which configPath's
                // own onConfigPathChanged triggers — a genuine synchronous
                // re-entrancy, not a false positive (see
                // docs/Development-Journal.md, Phase 2.0.5).
                visible: root.loader.loaded
                text: root.tokenLines.length + " token(s) loaded from " + root.themeName + "/theme.conf"
                color: "#5cb85c"
            }

            Text {
                text: "Live preview using loaded tokens:"
                color: "white"
                visible: root.loader.loaded
            }

            Row {
                spacing: root.theme.spacing.spacingSm
                visible: root.loader.loaded

                NebulaButton { theme: root.theme; label: "Primary"; variant: "primary" }
                NebulaButton { theme: root.theme; label: "Secondary"; variant: "secondary" }
                NebulaButton { theme: root.theme; label: "Ghost"; variant: "ghost" }
                NebulaAvatar { theme: root.theme; size: 48 }
            }

            Text {
                text: "Active tokens:"
                font.bold: true
                color: "white"
                visible: root.loader.loaded
            }

            Repeater {
                model: root.tokenLines

                Text {
                    text: modelData
                    color: "#a0a0a0"
                    font.family: "monospace"
                }
            }
        }
    }
}
