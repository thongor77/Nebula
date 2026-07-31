import QtQuick
import "../core/theme"
import "../core/components"
import "../core/layouts"
import "../core/services"
import "mocks"

// Manual visual harness demonstrating the Phase 2.3 completion criterion:
// a full login screen assembled only from Core components — user
// selection, password entry, session selection, power actions — talking
// only to Services (Mock adapters here, see docs/Login-Architecture.md).
// No SDDM dependency, no theme. Layering same as
// tests/LoginScreenHarness.qml, but with the real interactive components
// instead of a placeholder Text/Button:
//
//   NebulaBackground
//     NebulaWallpaper / NebulaOverlay
//     NebulaLoginLayout
//       NebulaSurface (main): Clock / Date / UserList / PasswordField
//       footer: SessionSelector / PowerButtons
//
// Run with `qml6 tests/LoginWorkflowHarness.qml` and interact with the
// keyboard/mouse — nothing here is scripted.
Item {
    id: harness
    width: 480
    height: 640

    property NebulaThemeProvider theme: NebulaThemeProvider {}

    NebulaUserService {
        id: userService
        adapter: MockUserAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: MockAuthAdapter {}
        onSucceeded: console.log("LoginWorkflowHarness: authentication succeeded")
        onFailed: (reason) => console.log("LoginWorkflowHarness: authentication failed —", reason)
    }

    NebulaSessionService {
        id: sessionService
        adapter: MockSessionAdapter {}
    }

    NebulaPowerService {
        id: powerService
        adapter: MockPowerAdapter {}
    }

    NebulaBackground {
        NebulaWallpaper {
            theme: harness.theme
            anchors.fill: parent
        }

        NebulaOverlay {
            theme: harness.theme
            anchors.fill: parent
        }

        NebulaLoginLayout {
            theme: harness.theme

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

                    NebulaUserList {
                        id: userList
                        theme: harness.theme
                        userService: userService
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: passwordField
                        onUserSelected: (user) => console.log("LoginWorkflowHarness: user selected —", user.name)
                    }

                    NebulaPasswordField {
                        id: passwordField
                        theme: harness.theme
                        authService: authService
                        username: userList.currentUser ? userList.currentUser.name : ""
                        placeholderText: "Password"
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: unlockButton
                        onSubmitted: console.log("LoginWorkflowHarness: password submitted")
                        onCleared: console.log("LoginWorkflowHarness: password field cleared")
                    }

                    NebulaButton {
                        id: unlockButton
                        theme: harness.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: authService.authenticating ? "Authenticating…" : "Unlock"
                        enabled: !authService.authenticating
                        variant: "primary"
                        onClicked: passwordField.submit()
                    }
                }
            }

            footerContent: Column {
                width: parent.width
                spacing: harness.theme.spacing.spacingMd

                NebulaSessionSelector {
                    theme: harness.theme
                    sessionService: sessionService
                    anchors.horizontalCenter: parent.horizontalCenter
                    onSessionSelected: (s) => console.log("LoginWorkflowHarness: session selected —", s.name)
                }

                NebulaPowerButtons {
                    theme: harness.theme
                    powerService: powerService
                    confirmBeforeAction: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    onShutdownRequested: console.log("LoginWorkflowHarness: shutdown requested")
                    onRebootRequested: console.log("LoginWorkflowHarness: reboot requested")
                    onSuspendRequested: console.log("LoginWorkflowHarness: suspend requested")
                    onHibernateRequested: console.log("LoginWorkflowHarness: hibernate requested")
                }
            }
        }
    }
}
