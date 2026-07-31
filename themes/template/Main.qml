import QtQuick
import "../../core/config"
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

    // NebulaThemeLoader doesn't exist yet (docs/Roadmap.md, Phase 1 build
    // order, item 3), so there is no Core-owned bridge from theme.conf's
    // flat keys to NebulaThemeConfig's grouped tokens. SDDM itself already
    // exposes theme.conf as the flat `config.<key>` context property
    // (confirmed real behavior, docs/Prototype-Results.md §3.2) — this
    // Main.qml applies those flat values onto its own NebulaThemeConfig
    // imperatively, since NebulaThemeConfig's groups are readonly and
    // don't support declarative per-token overrides (verified while
    // building this template — see docs/Development-Journal.md, Phase
    // 2.0). This is a temporary, per-theme stand-in for what
    // NebulaThemeLoader should eventually own; `config` is undefined
    // outside real SDDM (e.g. a quick standalone `qml6` preview), in
    // which case NebulaThemeConfig's own neutral defaults apply.
    property NebulaThemeConfig themeConfig: NebulaThemeConfig {}
    property NebulaThemeProvider theme: NebulaThemeProvider {
        config: root.themeConfig
    }

    function applyFlatValues(target, flatValues) {
        var groupNames = Object.keys(target).filter((key) => {
            return typeof target[key] === "object" && target[key] !== null
        })
        for (var i = 0; i < groupNames.length; i++) {
            var group = target[groupNames[i]]
            // `objectName` and every `xxxChanged` signal are also own
            // keys of a QtObject (see docs/Development-Journal.md, Phase
            // 1.6) — excluded here, not just real tokens. Skipping this
            // filter let a lookup of "objectNameChanged" reach the real
            // SDDM `config` object, which does return something
            // non-undefined for it (its own signal), which then failed
            // to assign back onto `group` (a read-only auto-generated
            // signal) — found by testing under real sddm-greeter, see
            // Phase 2.0 entry.
            var tokenNames = Object.keys(group).filter((key) => {
                return key !== "objectName" && typeof group[key] !== "function"
            })
            for (var j = 0; j < tokenNames.length; j++) {
                var tokenName = tokenNames[j]
                // Not `flatValues.hasOwnProperty(tokenName)`: when
                // `flatValues` is the real SDDM `config` context property,
                // it's a native QObject (SDDM::ThemeConfig), not a plain
                // JS object — hasOwnProperty doesn't exist on it (found by
                // testing under real sddm-greeter, see
                // docs/Development-Journal.md, Phase 2.0). Bracket access
                // returning undefined works on both a QObject and a plain
                // JS object.
                if (flatValues[tokenName] !== undefined) {
                    group[tokenName] = flatValues[tokenName]
                }
            }
        }
    }

    Component.onCompleted: {
        if (typeof config !== "undefined") {
            applyFlatValues(root.themeConfig, config)
        }
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
