import QtQuick
import "../core/theme"
import "../core/components"

// Manual visual harness demonstrating the Phase 1.2 completion criterion:
// a static login screen built only from Core components (Avatar, Clock,
// Date, Button) through NebulaThemeProvider, with no theme and no SDDM
// dependency. Not a theme — see docs/Theme-Development.md for what a
// real theme looks like. Run with `qml6 tests/LoginScreenHarness.qml`.
Rectangle {
    id: harness
    width: 480
    height: 520
    color: theme.colors.backgroundColor

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    Column {
        anchors.centerIn: parent
        spacing: harness.theme.spacing.spacingLg

        NebulaClock {
            theme: harness.theme
            anchors.horizontalCenter: parent.horizontalCenter
            showSeconds: true
        }

        NebulaDate {
            theme: harness.theme
            anchors.horizontalCenter: parent.horizontalCenter
        }

        NebulaAvatar {
            theme: harness.theme
            anchors.horizontalCenter: parent.horizontalCenter
            size: 96
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "nebula"
            color: harness.theme.colors.textPrimary
            font.family: harness.theme.typography.fontFamilyPrimary
            font.pixelSize: harness.theme.typography.fontSizeBody
        }

        NebulaButton {
            theme: harness.theme
            anchors.horizontalCenter: parent.horizontalCenter
            label: "Unlock"
            variant: "primary"
        }
    }
}
