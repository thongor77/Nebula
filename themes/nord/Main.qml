import QtQuick
import "../../core/theme"
import "../../core/components"
import "../../core/layouts"
import "../../core/services"
import "../../platform/sddm"

// Nord — Nebula's first official theme (Phase 2.1, see
// docs/Nord-Theme-Specification.md and docs/Nord-Validation-Report.md).
// Deliberately built with only the Core components that exist today
// (Background/Wallpaper/Overlay/LoginLayout/Surface/Avatar/Clock/Date/
// Button) — NebulaUserList/NebulaPasswordField/NebulaSessionSelector/
// NebulaPowerButtons/NebulaNotification don't exist yet. This is a
// deliberate scope decision (2026-07-31, see Nord-Validation-Report.md):
// this phase validates that the SDK/ThemeLoader/Design Tokens are
// sufficient to build a clean, coherent, maintainable theme without
// touching the Core — not a demand for a functionally complete login
// screen. Same structure as themes/template/Main.qml, styled with the
// real Nord palette instead of the Core's neutral fallback.
Item {
    id: root
    anchors.fill: parent

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
            source: Qt.resolvedUrl("assets/wallpapers/nord-gradient.png")
            mode: "crop"
        }

        NebulaOverlay {
            theme: root.theme
            anchors.fill: parent
            // Nord is already a dark, low-contrast palette — a light
            // flat veil keeps text legible over the wallpaper without
            // fighting the identity (see Nord-Theme-Specification.md §4:
            // static image, no GPU effects).
        }

        NebulaLoginLayout {
            theme: root.theme

            // Layout order per Nord-Theme-Specification.md §4: clock and
            // date at top, avatar and username in the middle, action
            // (Unlock) just below — same order a real NebulaPasswordField
            // would occupy once it exists.
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

            // statusContent/footerContent intentionally unused — no
            // NebulaNotification/NebulaPowerButtons yet, see
            // docs/Nord-Validation-Report.md.
        }
    }
}
