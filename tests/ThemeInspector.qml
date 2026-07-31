import QtQuick
import "../core/config"
import "../core/theme"

// Developer tool (Phase 2.1, optional per brief — see
// docs/Nord-Validation-Report.md): shows every active token, its
// effective value, and whether it comes from the theme or the Core's own
// default. A thin consumer of NebulaThemeLoader, like tests/ThemeHarness.qml
// — no loading logic of its own.
//
// Usage: QML_XHR_ALLOW_FILE_READ=1 qml6 tests/ThemeInspector.qml -- <ThemeName>
//   <ThemeName>  a directory under themes/ (default: "nord")
//
// Known limitation: origin is inferred by comparing the loaded value
// against a fresh, untouched NebulaThemeConfig — not by tracking which
// keys NebulaThemeLoader actually found in theme.conf (it doesn't expose
// that; adding it would be a Core change, out of scope this phase, see
// docs/Nord-Validation-Report.md). A theme.conf entry that happens to
// repeat the Core's own default value is indistinguishable from a token
// never mentioned at all — both show as "default" here.
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
        return "nord"
    }

    property NebulaThemeLoader loader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("../themes/" + root.themeName + "/theme.conf")
    }
    property NebulaThemeConfig defaultsConfig: NebulaThemeConfig {}

    property var tokenRows: {
        if (!root.loader.loaded) return []
        var rows = []
        var groupNames = Object.keys(root.loader.config).filter((key) => {
            return typeof root.loader.config[key] === "object" && root.loader.config[key] !== null
        })
        for (var i = 0; i < groupNames.length; i++) {
            var group = root.loader.config[groupNames[i]]
            var baseGroup = root.defaultsConfig[groupNames[i]]
            var tokenNames = Object.keys(group).filter((key) => {
                return key !== "objectName" && typeof group[key] !== "function"
            })
            for (var j = 0; j < tokenNames.length; j++) {
                var name = tokenNames[j]
                var value = "" + group[name]
                var defaultValue = "" + baseGroup[name]
                var origin = (value === defaultValue) ? "default" : "theme"
                rows.push({
                    name: groupNames[i] + "." + name,
                    value: value,
                    origin: origin
                })
            }
        }
        return rows
    }

    Rectangle {
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
                text: "ThemeInspector — " + root.themeName
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
                visible: root.loader.loaded
                text: root.tokenRows.length + " token(s) — " +
                    root.tokenRows.filter((r) => r.origin === "theme").length + " from " +
                    root.themeName + ", rest at Core default"
                color: "#5cb85c"
            }

            Repeater {
                model: root.tokenRows

                Row {
                    spacing: 12

                    Rectangle {
                        width: 70
                        height: 20
                        radius: 4
                        color: modelData.origin === "theme" ? "#5e81ac" : "#4b5263"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.origin
                            color: "white"
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        text: modelData.name + " = " + modelData.value
                        color: "#a0a0a0"
                        font.family: "monospace"
                    }
                }
            }
        }
    }
}
