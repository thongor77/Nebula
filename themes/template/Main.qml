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
//
// Mandatory vs optional (Phase 3.3, Developer-Experience-Review-2026.md
// §4/§5/§11): this file wires the full interactive set on purpose (it
// doubles as the SDK's technical reference), which can make it hard to
// tell what a simpler theme could safely drop. Mandatory for *any*
// theme with authentication: the theme/ThemeLoader/ThemeProvider
// wiring, NebulaUserService/NebulaAuthService, Background/Wallpaper/
// Overlay/LoginLayout/Surface, and the Clock/Date/UserList/
// PasswordField/Button column. Optional, marked individually below:
// the virtual keyboard toggle + NebulaVirtualKeyboard, session
// selection (NebulaSessionSelector), and power actions
// (NebulaPowerButtons) — a theme with a single session and no
// suspend/reboot/shutdown UI can drop all three without touching
// anything else.
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

    // Optional — only needed if the theme shows NebulaSessionSelector
    // (below). Drop this Service too if you drop that component.
    NebulaSessionService {
        id: sessionService
        adapter: SDDMSessionAdapter {}
    }

    // Optional — only needed if the theme shows NebulaPowerButtons
    // (below). Drop this Service too if you drop that component.
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
            // If you drop NebulaVirtualKeyboard (see below), also drop
            // this binding — bottomInset defaults to 0 on its own.
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

                // Optional block (with the matching NebulaVirtualKeyboard
                // instance below) — drop both together if your theme
                // doesn't need an on-screen keyboard toggle.
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

                // Optional — see NebulaSessionService above.
                NebulaSessionSelector {
                    theme: root.theme
                    sessionService: sessionService
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Optional — see NebulaPowerService above.
                NebulaPowerButtons {
                    theme: root.theme
                    powerService: powerService
                    confirmBeforeAction: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Optional — see the footer's keyboard toggle button above.
        NebulaVirtualKeyboard {
            id: virtualKeyboard
            theme: root.theme
            screenRoot: root
            passwordField: passwordField
            z: 1
        }
    }
}
