import QtQuick
import "../core/theme"
import "../core/components"
import "../core/layouts"
import "../core/services"
import "mocks"

// Manual visual harness demonstrating the Phase 1.5 completion criterion:
// a full pre-authentication login screen, layered exclusively from Core
// components through NebulaThemeProvider — no theme, no SDDM dependency.
// Layering (see docs/Rendering-Guidelines.md):
//
//   NebulaBackground
//     NebulaWallpaper   (fallback color only — no real wallpaper yet)
//     NebulaOverlay     (flat veil for legibility)
//     NebulaLoginLayout
//       NebulaSurface   (card around the functional content)
//         Avatar / Clock / Date / Button
//
// Run with `qml6 tests/LoginScreenHarness.qml`. See docs/Theme-SDK.md
// for what a real theme looks like (this harness is not one).
Item {
    id: harness
    width: 480
    height: 520

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    NebulaUserService {
        id: userService
        adapter: MockUserAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: MockAuthAdapter {}
    }

    NebulaBackground {
        NebulaWallpaper {
            theme: harness.theme
            anchors.fill: parent
            // No source: deliberately falls back to the flat theme
            // background color — this harness proves the Core layering,
            // not a wallpaper (no theme exists yet).
        }

        NebulaOverlay {
            theme: harness.theme
            anchors.fill: parent
        }

        NebulaLoginLayout {
            theme: harness.theme

            // Sole child of the Main Content Area — the zone hugs it
            // exactly (see NebulaLoginLayout.qml), so no anchors needed
            // here (same contract as NebulaSurface's own content below).
            NebulaSurface {
                theme: harness.theme
                shadowEnabled: true

                Column {
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
                        text: userService.currentUser ? userService.currentUser.displayName : "nebula"
                        color: harness.theme.colors.textPrimary
                        font.family: harness.theme.typography.fontFamilyPrimary
                        font.pixelSize: harness.theme.typography.fontSizeBody
                    }

                    NebulaButton {
                        theme: harness.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: authService.authenticating ? "Authenticating…" : "Unlock"
                        enabled: !authService.authenticating
                        variant: "primary"
                        onClicked: authService.authenticate(userService.currentUser.name, "fake-password")
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
