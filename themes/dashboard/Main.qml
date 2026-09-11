import QtQuick
import "../../core/theme"
import "../../core/components"
import "../../core/services"
import "../../platform/sddm"
import "components"
import "services"

// Dashboard — experimental triptych theme (evolved from the 2026-09-10
// architecture stress test, see docs/Dashboard-Theme-Report.md and the
// original docs/Dashboard-Architecture-Stress-Test.md). Not an official
// theme yet: a real daily-use experiment validating whether a
// left/center/right composition earns its place over repeated logins,
// and a GitHub showcase of what the frozen Core + Theme SDK already
// allow without any Core change.
//
// NebulaLoginLayout is still deliberately NOT used (its mainContent/
// statusContent zones are hard-capped to a single centered column by
// Core contract, see core/layouts/NebulaLoginLayout.qml) — the root
// layout below is hand-assembled from NebulaBackground + NebulaSurface
// + the interactive components, every one of them used exclusively
// through its documented public API.
//
// Content per region follows the brief exactly (a real change from the
// stress-test prototype, which mocked Host/Battery/Network system-info
// cards with static text): LEFT is pre-login context only (clock, date,
// theme wordmark), CENTER is identity+authentication, RIGHT is session/
// input/power controls. Nothing fake ships — no mocked labels, no
// telemetry, no system info the Core has no real Service for (see
// docs/Dashboard-Architecture-Stress-Test.md, Gap 3 — still unchanged).
Item {
    id: root
    anchors.fill: parent

    // --- Responsive tiers (theme-local, not theme.conf — see
    // docs/Dashboard-Architecture-Stress-Test.md Gap 2): below mediumBreakpoint the
    // triptych stops making sense as three simultaneous regions and
    // falls back to "authentication first", the brief's own suggested
    // small-screen strategy. Between the two, the same three regions
    // stay but compressed rather than dropped.
    property real wideBreakpoint: 1200
    property real mediumBreakpoint: 900
    readonly property bool isWide: root.width >= root.wideBreakpoint
    readonly property bool isMedium: !root.isWide && root.width >= root.mediumBreakpoint
    readonly property bool isNarrow: root.width < root.mediumBreakpoint

    // --- Power group bottom margin (layout experiment, round 3 — see the
    // comment at powerRow below). A small, fixed margin off the actual
    // bottom of `stage`, deliberately NOT derived from any other
    // dashboard spacing token — the group should read as a screen-edge
    // system control, not something visually tied to the rest of the
    // triptych's spacing rhythm.
    readonly property real _powerBottomMargin: 14

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
        onSucceeded: stage.opacity = 0
    }

    NebulaPowerService {
        id: powerService
        adapter: SDDMPowerAdapter {}
    }

    // Experimental, Dashboard-local only — see services/NetworkStatusModel.qml
    // and themes/dashboard/README.md. Not a Nebula Core service.
    NetworkStatusModel {
        id: networkModel
    }

    // Escape clears whatever was typed — the only "appropriate" Escape
    // behavior with a single field and no modal/dialog in the Core yet
    // (brief §4). Bubbles up here because NebulaPasswordField's internal
    // TextInput doesn't consume Escape itself.
    Keys.onEscapePressed: passwordField.clear()

    NebulaBackground {
        NebulaWallpaper {
            theme: root.theme
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/wallpapers/dashboard.jpg")
            mode: "crop"
        }

        NebulaOverlay {
            theme: root.theme
            anchors.fill: parent
        }

        Item {
            id: stage
            anchors.fill: parent
            anchors.margins: root.theme.spacing.spacingXl

            // Virtual keyboard pushes everything up uniformly, same
            // mental model as NebulaLoginLayout.bottomInset elsewhere —
            // overrides just the one anchor line set by anchors.fill
            // above, a normal QML pattern.
            anchors.bottomMargin: root.theme.spacing.spacingXl + virtualKeyboard.reservedHeight
            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: root.theme.animation.durationNormal }
            }

            // Whole-triptych entrance: one restrained fade+scale rather
            // than choreographing three panels separately (brief §4 —
            // "restrained", never delaying authentication).
            opacity: 0
            scale: 0.97
            Behavior on opacity {
                NumberAnimation { duration: root.theme.animation.durationNormal; easing.type: Easing.OutQuad }
            }
            Behavior on scale {
                NumberAnimation { duration: root.theme.animation.durationNormal; easing.type: Easing.OutQuad }
            }
            Component.onCompleted: { opacity = 1; scale = 1 }

            // --- CENTER — identity + authentication, always centered.
            // Safe with centerIn here (unlike a NebulaLoginLayout zone):
            // stage's own size never depends on centerCard's size, so no
            // binding loop (core/layouts/NebulaLoginLayout.qml documents
            // the same constraint for the case where it *would* loop).
            NebulaSurface {
                id: centerCard
                theme: root.theme
                shadowEnabled: true
                anchors.verticalCenter: parent.verticalCenter

                property bool hasError: authService.errorMessage.length > 0

                // Horizontal position set manually rather than
                // anchors.horizontalCenter, since the shake-on-error
                // offset below needs to compose with it (same pattern
                // as themes/glass-dark).
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

                Column {
                    spacing: root.theme.spacing.spacingLg
                    width: 260

                    NebulaUserList {
                        id: userList
                        theme: root.theme
                        userService: userService
                        anchors.horizontalCenter: parent.horizontalCenter
                        KeyNavigation.tab: passwordField
                        KeyNavigation.backtab: powerRow.lastFocusItem

                        // Brief pulse on user change, not a looping
                        // animation (Architecture.md §5.4).
                        scale: 1.0
                        Behavior on scale {
                            SequentialAnimation {
                                NumberAnimation { to: 1.04; duration: root.theme.animation.durationFast / 2 }
                                NumberAnimation { to: 1.0; duration: root.theme.animation.durationFast / 2 }
                            }
                        }
                        onUserSelected: scale = (scale === 1.0) ? 1.0001 : 1.0
                    }

                    NebulaPasswordField {
                        id: passwordField
                        theme: root.theme
                        authService: authService
                        username: userList.currentUser ? userList.currentUser.name : ""
                        placeholderText: "Password"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        KeyNavigation.tab: unlockButton
                        KeyNavigation.backtab: userList
                    }

                    // Fixed-height status line — always one line at a
                    // constant font size, so busy/error text never
                    // resizes the card (brief §4, "without layout
                    // jumps"). Empty string still reports the font's
                    // line height, not zero, so no reserved-space hack
                    // is needed beyond that.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.family: root.theme.typography.fontFamilySecondary
                        font.pixelSize: root.theme.typography.fontSizeBody * 0.85
                        color: centerCard.hasError ? root.theme.colors.errorColor : root.theme.colors.textSecondary
                        text: centerCard.hasError ? authService.errorMessage
                            : (authService.authenticating ? "Authenticating…" : "")
                    }

                    NebulaButton {
                        id: unlockButton
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: authService.authenticating ? "Authenticating…" : "Unlock"
                        enabled: !authService.authenticating
                        variant: "primary"
                        onClicked: passwordField.submit()
                        KeyNavigation.tab: sessionSelector
                        KeyNavigation.backtab: passwordField
                    }
                }
            }

            // --- LEFT — pre-login context only. Wide and medium: fixed
            // left column (this content is small enough to always fit
            // beside the card, unlike controlsPanel below). Narrow:
            // folds to just above the auth card instead of
            // disappearing — still visible, per brief §3's "fall back
            // cleanly ... secondary controls still reachable".
            NebulaSurface {
                id: contextPanel
                theme: root.theme

                // Plain numeric x/y rather than conditionally-set
                // anchors.* lines — QQuickAnchors kept a stale left
                // anchor active after root.isNarrow flipped false→true
                // during initial layout (both this panel and
                // controlsPanel landing on identical, nonsensical
                // geometry, found by actually running this under qml6
                // with mock adapters, see docs/Dashboard-Theme-Report.md).
                // Plain x/y bindings have no such "was this anchor line
                // ever cleared" state to go stale.
                x: root.isNarrow ? centerCard.x + (centerCard.width - width) / 2 : 0
                y: root.isNarrow
                    ? centerCard.y - height - root.theme.spacing.spacingMd
                    : centerCard.y + (centerCard.height - height) / 2

                Column {
                    width: root.isWide ? 220 : 180
                    spacing: root.theme.spacing.spacingSm

                    // The one piece of "branding" available without any
                    // new Core API (brief §2 — hostname/host info isn't:
                    // no Service exposes it, see
                    // docs/Dashboard-Architecture-Stress-Test.md Gap 3).
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.isWide
                        text: "N E B U L A"
                        font.family: root.theme.typography.fontFamilySecondary
                        font.pixelSize: root.theme.typography.fontSizeBody * 0.7
                        color: root.theme.colors.textSecondary
                        font.letterSpacing: 3
                    }

                    NebulaClock {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        showSeconds: root.isWide
                    }

                    NebulaDate {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // --- RIGHT — session, virtual keyboard, power. Wide: a right
            // column beside the card (Flow in TopToBottom mode == a
            // plain Column). Medium/narrow: folds below the card as one
            // wrapping block instead of vanishing — the concrete fix for
            // the prototype's "side panels just hide" behavior, since
            // the brief requires them to stay reachable (§3).
            //
            // Medium keeps this folded below rather than beside the card
            // (unlike contextPanel, which does stay beside it): real
            // measurement showed NebulaPowerButtons' 4-button Row — a
            // fixed Core internal that cannot itself wrap — never fits
            // in the space actually left beside the card at any medium
            // width up to wideBreakpoint, overlapping the card by up to
            // ~150px (found with an actual grabToImage() render, not
            // reasoned about on paper — see docs/Dashboard-Theme-Report.md).
            // Below the card there is always the full stage width to
            // wrap against instead.
            //
            // Power was moved out of this panel below (round 3) into its
            // own bottom-anchored group — see the comment at powerRow —
            // so controlsPanel's own visible/size no longer factor it in.
            NebulaSurface {
                id: controlsPanel
                theme: root.theme
                visible: sessionSelectorColumn.visible || keyboardToggle.visible
                    || (root.isWide && (networkModel.ethernetPresent || networkModel.wifiPresent))

                // See contextPanel above for why this is plain x/y, not
                // anchors.*.
                x: root.isWide ? stage.width - width : (stage.width - width) / 2
                y: root.isWide
                    ? centerCard.y + (centerCard.height - height) / 2
                    : centerCard.y + centerCard.height + root.theme.spacing.spacingMd

                Flow {
                    id: controlsFlow
                    flow: root.isWide ? Flow.TopToBottom : Flow.LeftToRight
                    spacing: root.theme.spacing.spacingMd
                    // Unconstrained width == a plain vertical stack when
                    // TopToBottom (wide only now). Medium/narrow need an
                    // actual width to wrap session/keyboard/power against
                    // — without it they ran off both screen edges (real
                    // bug, only visible once actually rendered — see
                    // docs/Dashboard-Theme-Report.md).
                    width: root.isWide ? undefined : stage.width - root.theme.spacing.spacingMd * 2

                    // Wide only — responsive priority (brief §8): network
                    // is expendable before session/keyboard/power, date/
                    // time, and above all authentication. Hidden outright
                    // below wideBreakpoint rather than squeezed in, same
                    // reasoning already applied to contextPanel/controlsPanel
                    // themselves for the narrow tier.
                    NetworkStatus {
                        theme: root.theme
                        model: networkModel
                        visible: root.isWide && (networkModel.ethernetPresent || networkModel.wifiPresent)
                        width: 180
                    }
                    Column {
                        id: sessionSelectorColumn
                        visible: sessionSelector.model.length > 0
                        spacing: root.theme.spacing.spacingXs

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.isWide
                            text: "Session"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }

                        NebulaSessionSelector {
                            id: sessionSelector
                            theme: root.theme
                            sessionService: sessionService
                            anchors.horizontalCenter: parent.horizontalCenter
                            KeyNavigation.tab: keyboardToggle.visible ? keyboardToggle : powerRow.firstFocusItem
                            KeyNavigation.backtab: unlockButton
                        }
                    }

                    NebulaButton {
                        id: keyboardToggle
                        theme: root.theme
                        visible: virtualKeyboard.available
                        label: virtualKeyboard.keyboardActive ? "Hide Keyboard" : "Show Keyboard"
                        onClicked: {
                            passwordField.forceActiveFocus()
                            virtualKeyboard.toggle()
                        }
                        KeyNavigation.tab: powerRow.firstFocusItem
                        KeyNavigation.backtab: sessionSelector
                    }
                }
            }

            // --- POWER — global machine actions (Shut Down/Restart/Sleep/
            // Hibernate). Layout experiment (2026-09-11): power controls
            // are not session/network context, so they no longer live
            // inside controlsPanel (RIGHT) — they get their own group,
            // stable at the bottom-center of the stage across every
            // breakpoint rather than folding into whichever tier the
            // triptych happens to be in.
            //
            // Round 3: no NebulaSurface wrapper at all, no opacity-
            // hierarchy tier — just the actions directly over the
            // wallpaper, anchored to the real bottom of `stage` with a
            // small fixed margin (`_powerBottomMargin`, ~14px)
            // deliberately NOT derived from spacingXl or any other
            // dashboard-panel spacing token, since a screen-edge system
            // control is meant to read differently from a dashboard
            // surface, not share its spacing rhythm. `anchors.bottom:
            // parent.bottom` (parent is `stage`) means virtual-keyboard
            // safety keeps working for free: stage's own bottomMargin
            // already grows by `virtualKeyboard.reservedHeight`, so the
            // anchor target itself moves up with it — nothing here needs
            // its own keyboard-awareness. Explicitly NOT vertically
            // related to controlsPanel (brief point 3) — only stage's
            // bottom edge.
            //
            // Uses the theme-local PowerActions (themes/dashboard/components/)
            // instead of Core's NebulaPowerButtons — plain-text actions per
            // the user's mockup, which NebulaButton can't currently express
            // even via its "ghost" variant (always keeps a border at rest).
            // See PowerActions.qml for the full rationale; it still goes
            // through the same NebulaPowerService `powerRow` always used.
            // `firstFocusItem`/`lastFocusItem` (not `powerRow` itself, which
            // holds no focus) are what keyboardToggle/sessionSelector/
            // userList now target — see those bindings above.
            PowerActions {
                id: powerRow
                theme: root.theme
                powerService: powerService
                confirmBeforeAction: true
                tabTarget: userList
                backtabTarget: keyboardToggle.visible ? keyboardToggle : sessionSelector
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root._powerBottomMargin
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
