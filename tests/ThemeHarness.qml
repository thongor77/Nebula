import QtQuick
import "../core/config"
import "../core/theme"
import "../core/components"

// Standalone theme loader/visualizer — doesn't depend on any particular
// theme (see docs/Theme-SDK.md §6). Not a preview of the real
// NebulaThemeLoader (which doesn't exist yet, see docs/Roadmap.md, Phase
// 1 build order item 3): reads a theme's theme.conf directly via a local
// ini parser, since there is no SDDM `config` context property outside
// sddm-greeter (see docs/Development-Journal.md, Phase 2.0, for the
// equivalent finding in themes/template/Main.qml).
//
// Usage: QML_XHR_ALLOW_FILE_READ=1 qml6 tests/ThemeHarness.qml -- <ThemeName>
//   <ThemeName>  a directory under themes/ (default: "template")
//
// QML_XHR_ALLOW_FILE_READ=1 is required — local file reads via
// XMLHttpRequest are disabled by default in this Qt6 build (found while
// building this harness, see docs/Development-Journal.md, Phase 2.0).
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
    property string themeDir: "../themes/" + themeName + "/"
    property string loadError: ""
    property var parsedValues: ({})

    property NebulaThemeConfig themeConfig: NebulaThemeConfig {}
    property NebulaThemeProvider theme: NebulaThemeProvider {
        config: root.themeConfig
    }

    // Flattened once here (rather than nesting a nesting Repeater per
    // group) — QML's `modelData` doesn't carry into a Repeater's own
    // child Repeater cleanly, so a single flat list of "group.token = value"
    // strings is simpler to render than a two-level one.
    property var tokenLines: {
        if (root.loadError.length > 0) return []
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

    // Same technique as themes/template/Main.qml (duplicated on purpose —
    // both are temporary stand-ins for NebulaThemeLoader, see
    // docs/Development-Journal.md, Phase 2.0). `objectName`/`xxxChanged`
    // excluded: they're own keys of every QtObject, not real tokens
    // (found in Phase 1.6 while building tests/ThemeSyncCheck.qml).
    function applyFlatValues(target, flatValues) {
        var groupNames = Object.keys(target).filter((key) => {
            return typeof target[key] === "object" && target[key] !== null
        })
        for (var i = 0; i < groupNames.length; i++) {
            var group = target[groupNames[i]]
            var tokenNames = Object.keys(group).filter((key) => {
                return key !== "objectName" && typeof group[key] !== "function"
            })
            for (var j = 0; j < tokenNames.length; j++) {
                var tokenName = tokenNames[j]
                if (flatValues[tokenName] !== undefined) {
                    group[tokenName] = flatValues[tokenName]
                }
            }
        }
    }

    function readIniGeneral(path) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", path, false)
        xhr.send()
        if (xhr.status !== 0 && xhr.status !== 200) {
            throw "HTTP status " + xhr.status + " reading " + path
        }
        if (xhr.status === 0 && xhr.responseText.length === 0) {
            throw "could not read " + path + " — file missing, or local file reads are " +
                "disabled (set QML_XHR_ALLOW_FILE_READ=1)"
        }
        var result = {}
        var lines = xhr.responseText.split("\n")
        var inGeneral = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0 || line[0] === ";" || line[0] === "#") continue
            if (line[0] === "[") {
                inGeneral = (line === "[General]")
                continue
            }
            if (!inGeneral) continue
            var eq = line.indexOf("=")
            if (eq === -1) continue
            var key = line.substring(0, eq).trim()
            var value = line.substring(eq + 1).trim()
            result[key] = value
        }
        return result
    }

    Component.onCompleted: {
        try {
            root.parsedValues = readIniGeneral(Qt.resolvedUrl(root.themeDir + "theme.conf"))
            root.applyFlatValues(root.themeConfig, root.parsedValues)
            console.log("ThemeHarness: loaded", root.themeDir + "theme.conf —",
                Object.keys(root.parsedValues).length, "key(s)")
        } catch (e) {
            root.loadError = e.toString()
            console.error("ThemeHarness: FAILED to load", root.themeName + ":", root.loadError)
        }
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
                visible: root.loadError.length > 0
                text: "FAILED TO LOAD: " + root.loadError
                color: "#d9534f"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Text {
                visible: root.loadError.length === 0
                text: Object.keys(root.parsedValues).length + " key(s) read from " + root.themeDir + "theme.conf"
                color: "#5cb85c"
            }

            Text {
                text: "Live preview using loaded tokens:"
                color: "white"
                visible: root.loadError.length === 0
            }

            Row {
                spacing: root.theme.spacing.spacingSm
                visible: root.loadError.length === 0

                NebulaButton { theme: root.theme; label: "Primary"; variant: "primary" }
                NebulaButton { theme: root.theme; label: "Secondary"; variant: "secondary" }
                NebulaButton { theme: root.theme; label: "Ghost"; variant: "ghost" }
                NebulaAvatar { theme: root.theme; size: 48 }
            }

            Text {
                text: "Active tokens:"
                font.bold: true
                color: "white"
                visible: root.loadError.length === 0
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
