import QtQuick
import "../theme"

// Current date display, respecting the system locale by default. See
// docs/Core-API.md.
Text {
    id: root

    required property NebulaThemeProvider theme

    // Empty (default) = system locale, matching Qt.formatDate()'s own
    // default when no explicit Locale is passed.
    property string locale: ""
    property string dateFormat: "dddd d MMMM yyyy"

    property date now: new Date()

    color: theme.colors.textSecondary
    font.family: theme.typography.fontFamilyPrimary
    font.pixelSize: theme.typography.fontSizeBody
    font.weight: theme.typography.fontWeightNormal

    text: root.locale.length > 0
        ? root.now.toLocaleDateString(Qt.locale(root.locale), root.dateFormat)
        : Qt.formatDate(root.now, root.dateFormat)

    Timer {
        // The date only changes once a day, but recomputing once a
        // minute is cheap and trivially handles midnight rollover without
        // extra scheduling logic.
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
