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
// the actual platform/sddm/ adapters, not the mock adapters used by
// tests/LoginWorkflowHarness.qml. Since those adapters are still Phase
// 1.4 skeletons (empty users/sessions, every power capability false),
// this Main.qml gracefully shows an empty user list / no session
// selector / no power buttons when run for real — multi-user/
// multi-session interaction is only exercisable today via
// tests/LoginWorkflowHarness.qml's Mock adapters (see
// docs/Login-Architecture.md).
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

    NebulaSessionService {
        id: sessionService
        adapter: SDDMSessionAdapter {}
    }

    NebulaPowerService {
        id: powerService
        adapter: SDDMPowerAdapter {}
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
            id: loginLayout
            theme: root.theme
            bottomInset: virtualKeyboard.reservedHeight

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

                    NebulaUserList {
                        id: userList
                        theme: root.theme
                        userService: userService
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: passwordField
                    }

                    NebulaPasswordField {
                        id: passwordField
                        theme: root.theme
                        authService: authService
                        username: userList.currentUser ? userList.currentUser.name : ""
                        placeholderText: "Password"
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: unlockButton
                    }

                    NebulaButton {
                        id: unlockButton
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: authService.authenticating ? "Authenticating…" : "Unlock"
                        enabled: !authService.authenticating
                        variant: "primary"
                        onClicked: passwordField.submit()
                    }
                }
            }

            // statusContent unused — no NebulaNotification yet (see
            // docs/Roadmap.md).
            footerContent: Column {
                width: parent.width
                spacing: root.theme.spacing.spacingMd

                NebulaButton {
                    theme: root.theme
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: virtualKeyboard.available
                    label: virtualKeyboard.keyboardActive ? "Hide Keyboard" : "Show Keyboard"
                    onClicked: {
                        passwordField.forceActiveFocus()
                        virtualKeyboard.toggle()
                    }
                }

                NebulaSessionSelector {
                    theme: root.theme
                    sessionService: sessionService
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                NebulaPowerButtons {
                    theme: root.theme
                    powerService: powerService
                    confirmBeforeAction: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        NebulaVirtualKeyboard {
            id: virtualKeyboard
            theme: root.theme
            screenRoot: root
            passwordField: passwordField
            z: 1
        }
    }
}
