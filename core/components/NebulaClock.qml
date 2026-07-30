import QtQuick
import "../theme"

// Current time display, auto-updating. See docs/Core-API.md.
Text {
    id: root

    required property NebulaThemeProvider theme

    property bool use24HourFormat: true
    property bool showSeconds: false
    // Optional Qt date-format override (e.g. "hh:mm"). Empty (default)
    // means "derive the format from use24HourFormat/showSeconds" — see
    // docs/Core-Implementation-Status.md for why both exist.
    property string format: ""

    property date now: new Date()

    color: theme.colors.textPrimary
    font.family: theme.typography.fontFamilyPrimary
    font.pixelSize: theme.typography.fontSizeClock
    font.weight: theme.typography.fontWeightNormal

    function currentFormat() {
        if (root.format.length > 0) {
            return root.format
        }
        if (root.use24HourFormat) {
            return root.showSeconds ? "hh:mm:ss" : "hh:mm"
        }
        return root.showSeconds ? "h:mm:ss AP" : "h:mm AP"
    }

    text: Qt.formatDateTime(root.now, root.currentFormat())

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
