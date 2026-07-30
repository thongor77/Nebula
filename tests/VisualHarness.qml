import QtQuick
import "../core/theme"
import "../core/components"

// Shows every Core component on a single page — a quick way to spot
// visual regressions after a change, without rebuilding a full login
// screen each time (suggested alongside Phase 1.5, optional per
// docs/Core-Implementation-Status.md — not an automated test). Run with
// `qml6 tests/VisualHarness.qml`.
Rectangle {
    id: root
    width: 960
    height: 820
    color: theme.colors.backgroundColor

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.spacing.spacingLg
        spacing: root.theme.spacing.spacingXl

        Column {
            spacing: root.theme.spacing.spacingSm

            Text {
                text: "NebulaButton"
                color: root.theme.colors.textPrimary
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.family: root.theme.typography.fontFamilyPrimary
            }
            Row {
                spacing: root.theme.spacing.spacingMd
                NebulaButton { theme: root.theme; label: "Primary"; variant: "primary" }
                NebulaButton { theme: root.theme; label: "Secondary"; variant: "secondary" }
                NebulaButton { theme: root.theme; label: "Ghost"; variant: "ghost" }
                NebulaButton { theme: root.theme; label: "Disabled"; enabled: false }
            }
        }

        Column {
            spacing: root.theme.spacing.spacingSm

            Text {
                text: "NebulaAvatar"
                color: root.theme.colors.textPrimary
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.family: root.theme.typography.fontFamilyPrimary
            }
            Row {
                spacing: root.theme.spacing.spacingMd
                NebulaAvatar { theme: root.theme; size: 64 }
                NebulaAvatar { theme: root.theme; size: 64; radius: root.theme.radius.radiusMedium }
            }
        }

        Column {
            spacing: root.theme.spacing.spacingSm

            Text {
                text: "NebulaClock / NebulaDate"
                color: root.theme.colors.textPrimary
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.family: root.theme.typography.fontFamilyPrimary
            }
            NebulaClock { theme: root.theme; showSeconds: true }
            NebulaDate { theme: root.theme }
        }

        Column {
            spacing: root.theme.spacing.spacingSm

            Text {
                text: "NebulaSurface"
                color: root.theme.colors.textPrimary
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.family: root.theme.typography.fontFamilyPrimary
            }
            NebulaSurface {
                theme: root.theme
                shadowEnabled: true

                Text {
                    text: "Card content"
                    color: root.theme.colors.textPrimary
                }
            }
        }

        Column {
            spacing: root.theme.spacing.spacingSm

            Text {
                text: "NebulaBackground / NebulaWallpaper / NebulaOverlay"
                color: root.theme.colors.textPrimary
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.family: root.theme.typography.fontFamilyPrimary
            }
            Item {
                width: 320
                height: 140

                NebulaBackground {
                    NebulaWallpaper {
                        theme: root.theme
                        anchors.fill: parent
                        source: "file:///usr/share/wallpapers/EndeavourOS/contents/screenshot.png"
                    }
                    NebulaOverlay {
                        theme: root.theme
                        anchors.fill: parent
                        useGradient: true
                        color2: "#000000"
                    }
                }
            }
        }
    }
}
