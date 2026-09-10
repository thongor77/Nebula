import QtQuick
import "../../core/theme"
import "../../core/components"
import "../../core/services"
import "../../platform/sddm"

// Dashboard — architecture stress-test prototype (2026-09-10), NOT a
// production theme. Full findings: docs/Dashboard-Architecture-Stress-Test.md.
// Functional composition only, no final art — the brief explicitly asks
// for that ("prioritize functional composition over polish").
//
// This file exists to *verify by running* the two claims the written
// analysis made on paper:
//
// 1. A left+center+right composition is reachable without any Core
//    change, by using every component through its normal documented API
//    but assembling the root layout by hand instead of through
//    NebulaLoginLayout (see Gap 1) — NebulaLoginLayout is intentionally
//    NOT imported here.
// 2. Theme-specific toggles (showLeftPanel/showRightPanel below) work as
//    plain QML properties, without touching theme.conf or
//    NebulaThemeLoader (see Gap 2, option 1).
//
// Left/right panel "system status" content (Host, Battery, Network) is
// deliberately static/mocked text, NOT backed by any Service — there is
// no NebulaSystemInfoService in the Core (Gap 3: no SDDM context
// property exposes this, and a single theme doesn't meet the API-freeze
// "more than one theme" bar to justify adding one). A real Dashboard
// theme would need that Service designed and built first.
Item {
    id: root
    anchors.fill: parent

    // --- Theme-local configuration (Gap 2, option 1) -------------------
    // Deliberately NOT theme.conf keys: NebulaThemeLoader only ever
    // writes into pre-existing NebulaThemeConfig token names and silently
    // discards anything else (core/theme/NebulaThemeLoader.qml). Plain
    // QML properties are the correct home for Dashboard-specific toggles
    // today — Glass already uses the same pattern for its animation
    // parameters.
    property bool showLeftPanel: true
    property bool showRightPanel: true

    // Side panels only make sense once there is real spare width beside
    // the centered auth card — below this, fall back to "auth first",
    // the brief's own suggested small-screen strategy.
    readonly property bool wideEnough: root.width >= 1100

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

    NebulaSessionService {
        id: sessionService
        adapter: SDDMSessionAdapter {}
    }

    NebulaAuthService {
        id: authService
        adapter: SDDMAuthAdapter {}
        sessionService: sessionService
        onSucceeded: dashboard.opacity = 0
    }

    NebulaPowerService {
        id: powerService
        adapter: SDDMPowerAdapter {}
    }

    NebulaBackground {
        NebulaWallpaper {
            theme: root.theme
            anchors.fill: parent
            // No source shipped for this prototype — falls back to the
            // flat theme.conf backgroundColor, same convention as
            // themes/template.
        }

        NebulaOverlay {
            theme: root.theme
            anchors.fill: parent
        }

        // NebulaLoginLayout is deliberately NOT used here (see Gap 1):
        // its mainContent/statusContent zones are hard-capped to a
        // single centered column by Core contract
        // (core/layouts/NebulaLoginLayout.qml), which cannot host a
        // left+center+right composition. Every component below is still
        // used exclusively through its documented Core API.
        Item {
            id: dashboard
            anchors.fill: parent
            anchors.margins: root.theme.spacing.spacingXl

            Behavior on opacity {
                NumberAnimation { duration: root.theme.animation.durationNormal }
            }

            // --- Left panel: system status (mocked, see Gap 3) --------
            Column {
                id: leftPanel
                visible: root.wideEnough && root.showLeftPanel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.spacing.spacingMd

                NebulaSurface {
                    theme: root.theme
                    Column {
                        width: 200
                        spacing: root.theme.spacing.spacingSm
                        Text {
                            text: "Host"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }
                        Text {
                            // Mocked — no NebulaSystemInfoService exists (Gap 3).
                            text: "nebula-dashboard"
                            color: root.theme.colors.textPrimary
                            font.family: root.theme.typography.fontFamilyPrimary
                            font.pixelSize: root.theme.typography.fontSizeBody
                        }
                    }
                }

                NebulaSurface {
                    theme: root.theme
                    Column {
                        width: 200
                        spacing: root.theme.spacing.spacingSm
                        Text {
                            text: "Battery"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }
                        Text {
                            // Mocked — same limitation as above.
                            text: "— (no Core Service today)"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilyPrimary
                            font.pixelSize: root.theme.typography.fontSizeBody
                        }
                    }
                }

                NebulaSurface {
                    theme: root.theme
                    Column {
                        width: 200
                        spacing: root.theme.spacing.spacingSm
                        Text {
                            text: "Network"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }
                        Text {
                            // Mocked — same limitation as above.
                            text: "— (no Core Service today)"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilyPrimary
                            font.pixelSize: root.theme.typography.fontSizeBody
                        }
                    }
                }
            }

            // --- Center: identity + authentication, fully real -------
            NebulaSurface {
                id: centerCard
                theme: root.theme
                shadowEnabled: true
                anchors.centerIn: parent
                // Safe here (unlike a NebulaLoginLayout zone): dashboard's
                // own size never depends on centerCard's size, so no
                // binding loop (see core/layouts/NebulaLoginLayout.qml
                // comment on the same constraint).

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

            // --- Right panel: session + input ------------------------
            Column {
                id: rightPanel
                visible: root.wideEnough && root.showRightPanel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.spacing.spacingMd

                NebulaSurface {
                    theme: root.theme
                    Column {
                        width: 200
                        spacing: root.theme.spacing.spacingSm
                        Text {
                            text: "Session"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }
                        NebulaSessionSelector {
                            theme: root.theme
                            sessionService: sessionService
                        }
                    }
                }

                NebulaSurface {
                    theme: root.theme
                    Column {
                        width: 200
                        spacing: root.theme.spacing.spacingSm
                        Text {
                            text: "Keyboard"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }
                        Text {
                            // Mocked — NebulaKeyboardSelector is documented
                            // in Core-API.md but never implemented; no
                            // layout-name data exists to show here yet.
                            text: "Layout: (selector not implemented)"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilyPrimary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.85
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        NebulaButton {
                            // Real, unlike the label above — NebulaVirtualKeyboard
                            // is a real, implemented Core component.
                            theme: root.theme
                            visible: virtualKeyboard.available
                            label: virtualKeyboard.keyboardActive ? "Hide Keyboard" : "Show Keyboard"
                            onClicked: {
                                passwordField.forceActiveFocus()
                                virtualKeyboard.toggle()
                            }
                        }
                    }
                }
            }

            // --- Bottom: power actions, always reachable --------------
            NebulaPowerButtons {
                theme: root.theme
                powerService: powerService
                confirmBeforeAction: true
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: Math.min(virtualKeyboard.reservedHeight, dashboard.height / 2)

                Behavior on anchors.bottomMargin {
                    NumberAnimation { duration: root.theme.animation.durationNormal }
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
