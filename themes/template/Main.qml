import QtQuick
import "../../core/theme"
import "../../core/components"
import "../../core/layouts"
import "../../core/services"
import "../../platform/sddm"

// Neutral base template — copy this directory to start a new theme (see
// docs/Creating-A-Theme.md). Rules for what a theme may/must never do:
// docs/Theme-SDK.md.
//
// This file demonstrates the real production wiring: Services backed by
// the actual (Phase 1.4 skeleton) platform/sddm/ adapters, not the mock
// adapters used by tests/LoginScreenHarness.qml. It only assembles Core
// components that exist today (Background/Wallpaper/Overlay/LoginLayout/
// Surface/Avatar/Clock/Date/Button) — NebulaUserList/NebulaPasswordField/
// NebulaSessionSelector/NebulaPowerButtons don't exist yet (see
// docs/Roadmap.md, Phase 1 build order), so there is no real username
// input or password field here yet, same limitation as the harness.
Item {
    id: root
    anchors.fill: parent

    // NebulaThemeLoader (Phase 2.0.5, see docs/ThemeLoader.md) is now the
    // sole owner of reading theme.conf — it reads the file directly, not
    // via SDDM's `config` context property, so this works identically
    // under real SDDM, `sddm-greeter --test-mode`, and standalone `qml6`.
    property NebulaThemeLoader themeLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("theme.conf")
    }
    property NebulaThemeProvider theme: NebulaThemeProvider {
        config: root.themeLoader.config
    }

    NebulaUserService {
        id: userService
        adapter: SDDMUserAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: SDDMAuthAdapter {}
    }

    NebulaBackground {
        NebulaWallpaper {
            theme: root.theme
            anchors.fill: parent
            // No source shipped in the Template — falls back to the flat
            // theme background color. Add a real image under
            // assets/wallpapers/ and set `source` for an actual theme.
        }

        NebulaOverlay {
            theme: root.theme
            anchors.fill: parent
        }

        NebulaLoginLayout {
            theme: root.theme

            NebulaSurface {
                theme: root.theme
                shadowEnabled: true

                Column {
                    spacing: root.theme.spacing.spacingLg

                    NebulaClock {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        showSeconds: true
                    }

                    NebulaDate {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    NebulaAvatar {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 96
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: userService.currentUser ? userService.currentUser.displayName : "Nebula"
                        color: root.theme.colors.textPrimary
                        font.family: root.theme.typography.fontFamilyPrimary
                        font.pixelSize: root.theme.typography.fontSizeBody
                    }

                    NebulaButton {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: authService.authenticating ? "Authenticating…" : "Unlock"
                        enabled: !authService.authenticating
                        variant: "primary"
                        onClicked: authService.authenticate(
                            userService.currentUser ? userService.currentUser.name : "",
                            "")
                    }
                }
            }

            // statusContent and footerContent stay unused here — nothing
            // to put in them yet (NebulaNotification, NebulaPowerButtons,
            // ... don't exist until later phases). See
            // docs/Core-Implementation-Status.md.
        }
    }
}
