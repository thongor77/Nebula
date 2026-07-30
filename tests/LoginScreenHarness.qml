import QtQuick
import "../core/theme"
import "../core/components"
import "../core/layouts"
import "../core/services"
import "mocks"

// Manual visual harness demonstrating the Phase 1.3 completion criterion:
// a full (pre-authentication) login screen built from a single
// NebulaLoginLayout instance, itself populated only with Core components
// (Avatar, Clock, Date, Button) through NebulaThemeProvider — no theme,
// no SDDM dependency. See docs/Theme-Development.md for what a real
// theme looks like. Run with `qml6 tests/LoginScreenHarness.qml`.
//
// Phase 1.4: also wires NebulaUserService and NebulaAuthService (with
// mock adapters, see tests/mocks/) to prove the Service layer works
// without SDDM — the display name comes from the service, and the
// button drives a real (fake) authenticate() round-trip. No
// NebulaPasswordField/UserList exist yet to do this properly; this is a
// deliberately minimal proof, not a preview of the real login flow — see
// docs/Core-Implementation-Status.md.
Rectangle {
    id: harness
    width: 480
    height: 520
    color: theme.colors.backgroundColor

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    NebulaUserService {
        id: userService
        adapter: MockUserAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: MockAuthAdapter {}
    }

    NebulaLoginLayout {
        theme: harness.theme

        // Anonymous child — lands in the Main Content Area (the default
        // zone), matching the previous manual assembly. Horizontal
        // centering only: the zone's height already hugs this content
        // exactly (see NebulaLoginLayout.qml), so vertically centering
        // this Column *within* it would create a binding loop — see
        // docs/Development-Journal.md.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
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

        // statusContent and footerContent stay unused here — nothing to
        // put in them yet (NebulaNotification, NebulaPowerButtons, ...
        // don't exist until later phases). Demonstrating them is not
        // this harness's job; docs/Core-Implementation-Status.md notes
        // this explicitly.
    }
}
