import QtQuick
import "../../core/theme"
import "../../core/components"
import "../../core/layouts"
import "../../core/services"
import "../../platform/sddm"

// Glass — Nebula's second official theme, dark variant (Phase 3.0, see
// docs/Glass-Theme-Report.md). Fluent Design / modern Breeze / macOS
// Sonoma inspired: sober frosted-glass feel achieved entirely through
// NebulaSurface/NebulaOverlay opacity tokens — no GPU blur (Core doesn't
// have one yet, see docs/Rendering-Guidelines.md). Same component set
// and wiring as themes/template/Main.qml; glass-light/Main.qml is kept
// identical to this file on purpose (only theme.conf/wallpaper differ
// between the two variants) — a repo-level convenience, not a new SDK
// mechanism (see docs/Glass-Theme-Report.md).
//
// Themed animations (brief §Animations, 150-250ms, see theme.conf's
// durationFast override): card appears with a fade+scale on load, fades
// out on successful authentication, the user selector gives a brief
// pulse on selection, and the password field shakes once on a failed
// attempt. Focus feedback itself is NebulaButton/NebulaPasswordField's
// own built-in Behavior (already covered by Core tests) — not
// reimplemented here.
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
        sessionService: sessionService
        onSucceeded: card.opacity = 0
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
            source: Qt.resolvedUrl("assets/wallpapers/glass-dark.png")
            mode: "crop"
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
                id: card
                theme: root.theme
                shadowEnabled: true
                // Tuned via a standalone opacity/radius/shadow comparison
                // (4 combinations, see docs/Glass-Theme-Report.md) — 0.3/4
                // read as a soft, defined separation without the card
                // looking pasted-on.
                shadowOpacity: 0.3
                shadowOffset: 4

                // Appear: fade + scale in on load.
                opacity: 0
                scale: 0.96
                Behavior on opacity {
                    NumberAnimation { duration: root.theme.animation.durationNormal; easing.type: Easing.OutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: root.theme.animation.durationNormal; easing.type: Easing.OutQuad }
                }
                Component.onCompleted: {
                    opacity = 1
                    scale = 1
                }

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

                        // User change: a brief pulse rather than a
                        // permanent/looping animation (Architecture.md
                        // §5.4).
                        scale: 1.0
                        Behavior on scale {
                            SequentialAnimation {
                                NumberAnimation { to: 1.04; duration: root.theme.animation.durationFast / 2 }
                                NumberAnimation { to: 1.0; duration: root.theme.animation.durationFast / 2 }
                            }
                        }
                        onUserSelected: scale = (scale === 1.0) ? 1.0001 : 1.0 // nudge to retrigger the Behavior
                    }

                    NebulaPasswordField {
                        id: passwordField
                        theme: root.theme
                        authService: authService
                        username: userList.currentUser ? userList.currentUser.name : ""
                        placeholderText: "Password"
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: unlockButton

                        // Password validation: a single shake on error,
                        // not a permanent effect.
                        property int shakeOffset: 0
                        x: (parent.width - width) / 2 + shakeOffset
                        Behavior on shakeOffset {
                            SequentialAnimation {
                                NumberAnimation { to: -8; duration: 40 }
                                NumberAnimation { to: 8; duration: 80 }
                                NumberAnimation { to: 0; duration: 40 }
                            }
                        }
                        onHasErrorChanged: if (hasError) shakeOffset = (shakeOffset === 0) ? 1 : 0
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
