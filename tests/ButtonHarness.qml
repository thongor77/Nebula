import QtQuick
import "../core/theme"
import "../core/components"

// Manual visual harness for NebulaButton — not an automated test (the
// concrete test framework is still open, see tests/README.md). Run with
// `qml6 tests/ButtonHarness.qml` and inspect visually: colors per
// variant, size, radius, normal/disabled state, and press feedback
// (click and hold to see the scale/color animation).
Rectangle {
    id: harness
    width: 500
    height: 360
    color: theme.colors.backgroundColor

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    Column {
        anchors.centerIn: parent
        spacing: harness.theme.spacing.spacingLg

        Row {
            spacing: harness.theme.spacing.spacingMd

            NebulaButton {
                theme: harness.theme
                label: "Primary"
                variant: "primary"
                onClicked: console.log("Primary clicked")
            }

            NebulaButton {
                theme: harness.theme
                label: "Secondary"
                variant: "secondary"
                onClicked: console.log("Secondary clicked")
            }

            NebulaButton {
                theme: harness.theme
                label: "Ghost"
                variant: "ghost"
                onClicked: console.log("Ghost clicked")
            }
        }

        Row {
            spacing: harness.theme.spacing.spacingMd

            NebulaButton {
                theme: harness.theme
                label: "Disabled"
                variant: "primary"
                enabled: false
            }

            NebulaButton {
                theme: harness.theme
                label: "Focused (Tab to me)"
                variant: "primary"
                focus: true
            }
        }
    }
}
