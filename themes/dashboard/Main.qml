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
    // docs/Dashboard-Architecture-Stress-Test.md Gap 2). Originally drove
    // structural layout changes (folding panels below the card, hiding
    // secondary details) below wideBreakpoint/mediumBreakpoint. As of
    // round 6 (2026-09-11, "consistent triptych at all screen sizes" —
    // same composition at every tier, only continuous uiScale scaling,
    // no structural repositioning) nothing in this file branches on
    // isWide/isMedium/isNarrow anymore — kept defined, unused, rather
    // than deleted, since the brief that drove this change explicitly
    // allows "tighter spacing when needed, reduced secondary details if
    // needed" as still-permitted future responsive behavior, just not a
    // default. Revisit/remove if no such use appears.
    property real wideBreakpoint: 1200
    property real mediumBreakpoint: 900
    readonly property bool isWide: root.width >= root.wideBreakpoint
    readonly property bool isMedium: !root.isWide && root.width >= root.mediumBreakpoint
    readonly property bool isNarrow: root.width < root.mediumBreakpoint

    // --- Adaptive scale (theme-local, same rationale as the breakpoints
    // above — see docs/Dashboard-Architecture-Stress-Test.md Gap 2).
    // `root.width`/`root.height` are already THIS screen's logical (DIP)
    // size — Qt/Wayland resolves each output's own scale factor before
    // QML ever sees them, which is exactly why a mixed-DPI multi-monitor
    // setup (see [[nebula-virtual-keyboard-scaling]]) doesn't need any
    // extra DPI detection here. What's missing without this block is
    // continuity: wideBreakpoint/mediumBreakpoint only decide WHICH
    // regions are shown, so a low-logical-resolution screen sitting in
    // the same tier as a high one rendered every card/font/avatar at an
    // identical fixed pixel size regardless of how much logical room it
    // actually had. `uiScale` fixes that by re-deriving every Design
    // System token from the theme's OWN loaded base values (never a
    // second-guessed hardcoded copy) each time it changes, so a card
    // resized on a bigger logical screen keeps the exact same relative
    // proportions, just bigger — never a blurry magnified bitmap, since
    // real pixelSize/width/height/radius numbers are being recomputed,
    // not a `scale:` transform on already-laid-out content. Deliberately
    // NOT applied to wideBreakpoint/mediumBreakpoint themselves — the
    // brief asks to keep the triptych's geometry/proportions unchanged,
    // i.e. which tier is chosen; only how big that tier renders.
    readonly property real _referenceWidth: 1920
    readonly property real _referenceHeight: 1080
    readonly property real _rawUiScale: Math.min(root.width / root._referenceWidth, root.height / root._referenceHeight)
    readonly property real uiScale: Math.max(0.65, Math.min(1.35, root._rawUiScale))

    // Snapshot of the theme's own token values exactly as theme.conf (or
    // Core's own defaults, for anything theme.conf doesn't set) resolved
    // them, taken once after load. Every `_applyUiScale()` call scales
    // from THIS, never from the config's current (possibly already
    // scaled) value — otherwise repeated scale changes would compound.
    property var _baseTokens: null

    function _snapshotBaseTokens() {
        var cfg = root.themeLoader.config
        root._baseTokens = {
            spacingXs: cfg.spacing.spacingXs, spacingSm: cfg.spacing.spacingSm,
            spacingMd: cfg.spacing.spacingMd, spacingLg: cfg.spacing.spacingLg,
            spacingXl: cfg.spacing.spacingXl,
            fontSizeTitle: cfg.typography.fontSizeTitle,
            fontSizeBody: cfg.typography.fontSizeBody,
            fontSizeClock: cfg.typography.fontSizeClock,
            radiusSmall: cfg.radius.radiusSmall, radiusMedium: cfg.radius.radiusMedium,
            radiusLarge: cfg.radius.radiusLarge,
            surfaceBorderWidth: cfg.surface.surfaceBorderWidth,
            borderWidthThin: cfg.interaction.borderWidthThin,
            borderWidthFocus: cfg.interaction.borderWidthFocus
        }
    }

    // Mutates the loaded NebulaThemeConfig's token values in place. Safe
    // because this theme owns its own NebulaThemeLoader/config instance
    // (one per screen) and every Core component that sizes itself purely
    // from theme tokens (NebulaButton, NebulaPasswordField,
    // NebulaSessionSelector, NebulaPowerButtons, NebulaSurface's default
    // padding, NebulaClock, NebulaDate) already reads through
    // NebulaThemeProvider (DT-0006) — rewriting the values it aliases
    // makes them all re-lay-out coherently with zero Core change.
    function _applyUiScale() {
        if (!root._baseTokens) return
        var cfg = root.themeLoader.config
        var b = root._baseTokens
        var s = root.uiScale
        cfg.spacing.spacingXs = b.spacingXs * s
        cfg.spacing.spacingSm = b.spacingSm * s
        cfg.spacing.spacingMd = b.spacingMd * s
        cfg.spacing.spacingLg = b.spacingLg * s
        cfg.spacing.spacingXl = b.spacingXl * s
        cfg.typography.fontSizeTitle = Math.round(b.fontSizeTitle * s)
        cfg.typography.fontSizeBody = Math.round(b.fontSizeBody * s)
        cfg.typography.fontSizeClock = Math.round(b.fontSizeClock * s)
        cfg.radius.radiusSmall = b.radiusSmall * s
        cfg.radius.radiusMedium = b.radiusMedium * s
        cfg.radius.radiusLarge = b.radiusLarge * s
        cfg.surface.surfaceBorderWidth = Math.max(1, Math.round(b.surfaceBorderWidth * s))
        cfg.interaction.borderWidthThin = Math.max(1, Math.round(b.borderWidthThin * s))
        cfg.interaction.borderWidthFocus = Math.max(1, Math.round(b.borderWidthFocus * s))
    }

    onUiScaleChanged: root._applyUiScale()

    // --- Visual refinement pass (surfaces only, theme-local — no Core
    // change). NebulaSurface's `surfaceColor`/`borderColor` are plain
    // overridable instance properties (unlike `theme.surface.surfaceOpacity`,
    // a single value shared by every surface theme-wide), so per-surface
    // translucency/border weight is expressed by baking an alpha into a
    // color built from the theme's own base tokens — never a hardcoded
    // hex, and dividing out the shared surfaceOpacity multiplier so the
    // requested target opacity (verified against the real wallpaper via
    // offscreen grabToImage renders at 85/75/65%, all readable with
    // textPrimary contrast >= 12:1 and textSecondary >= 4.8:1) is exact
    // regardless of theme.conf's own surfaceOpacity value. Center stays
    // the most opaque/defined surface (primary, authentication); the two
    // side surfaces are quieter, the right (session/keyboard/power)
    // quietest of all per brief.
    function _panelColor(targetOpacity) {
        var c = root.theme.colors.surfaceColor
        var shared = root.theme.surface.surfaceOpacity || 1.0
        return Qt.rgba(c.r, c.g, c.b, Math.min(1.0, targetOpacity / shared))
    }
    function _panelBorder(targetAlpha) {
        var c = root.theme.colors.textSecondary
        return Qt.rgba(c.r, c.g, c.b, targetAlpha)
    }

    // --- Power group bottom margin (layout experiment, round 3 — see the
    // comment at powerRow below). A small, fixed margin off the actual
    // bottom of `stage`, deliberately NOT derived from any other
    // dashboard spacing token — the group should read as a screen-edge
    // system control, not something visually tied to the rest of the
    // triptych's spacing rhythm.
    readonly property real _powerBottomMargin: Math.round(14 * root.uiScale)

    property NebulaThemeLoader themeLoader: NebulaThemeLoader {
        configPath: Qt.resolvedUrl("theme.conf")
    }
    property NebulaThemeProvider theme: NebulaThemeProvider {
        config: root.themeLoader.config
    }

    Component.onCompleted: {
        root._snapshotBaseTokens()
        root._applyUiScale()
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
                shadowOffset: Math.max(1, Math.round(2 * root.uiScale))
                shadowOpacity: 0.32
                surfaceColor: root._panelColor(0.85)
                borderColor: root._panelBorder(0.5)
                padding: root.theme.spacing.spacingLg
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
                    width: Math.round(260 * root.uiScale)

                    NebulaUserList {
                        id: userList
                        theme: root.theme
                        userService: userService
                        avatarSize: Math.round(64 * root.uiScale)
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
                surfaceColor: root._panelColor(0.72)
                borderColor: root._panelBorder(0.2)
                padding: root.theme.spacing.spacingLg

                // Round 6 (2026-09-11, user feedback: "consistent triptych
                // at all screen sizes" — same composition/position at
                // every tier, only continuous uiScale proportional
                // scaling, no structural repositioning). Previously
                // folded above the card at the narrow tier; now always
                // beside it, same as wide/medium, per that brief. Plain
                // x/y (not anchors.*) is no longer load-bearing for the
                // stale-anchor reason that originally motivated it (that
                // was specifically about the isNarrow fold flipping at
                // runtime, which no longer exists) but left as plain x/y
                // anyway — no reason to touch a working, simpler binding
                // style just because its original justification changed.
                x: 0
                y: centerCard.y + (centerCard.height - height) / 2

                Column {
                    width: Math.round(220 * root.uiScale)
                    spacing: root.theme.spacing.spacingXs

                    // The one piece of "branding" available without any
                    // new Core API (brief §2 — hostname/host info isn't:
                    // no Service exposes it, see
                    // docs/Dashboard-Architecture-Stress-Test.md Gap 3).
                    // Dimmed further (visual refinement pass) — a label,
                    // not information competing with the clock/date it
                    // sits above. Always shown now (round 6) — no longer
                    // tiered by isWide, per "no structural change"/no
                    // secondary-detail reduction in the user's brief.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "N E B U L A"
                        font.family: root.theme.typography.fontFamilySecondary
                        font.pixelSize: root.theme.typography.fontSizeBody * 0.7
                        color: root.theme.colors.textSecondary
                        opacity: 0.65
                        font.letterSpacing: 4
                    }

                    NebulaClock {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                        showSeconds: true
                    }

                    NebulaDate {
                        theme: root.theme
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // --- RIGHT — session, virtual keyboard, power. A right column
            // beside the card (Flow in TopToBottom mode == a plain
            // Column).
            //
            // Round 6 (2026-09-11, user feedback: "consistent triptych at
            // all screen sizes" — same composition at every tier, only
            // continuous uiScale scaling, no structural repositioning).
            // Previously folded below the card at medium/narrow because
            // NebulaPowerButtons' fixed-width 4-button Row couldn't fit
            // beside the card at those widths (see
            // docs/Dashboard-Theme-Report.md) — but Power was extracted
            // to its own bottom-anchored group earlier this session
            // (round 3), so that reason is gone: the only remaining
            // content (Network/Session/Keyboard) already fits beside the
            // card at every tested width once it's content-sized rather
            // than force-widened (round 4). Now always beside the card,
            // same as wide.
            NebulaSurface {
                id: controlsPanel
                theme: root.theme
                surfaceColor: root._panelColor(0.65)
                borderColor: root._panelBorder(0.16)
                padding: root.theme.spacing.spacingLg
                // Reads the same underlying conditions sessionSelectorColumn/
                // keyboardToggle each use for their own `visible`, rather than
                // those children's `.visible` properties directly — binding a
                // parent's visible to its own descendants' visible triggers a
                // real QML binding loop (Qt Quick propagates visibility
                // changes down to children, which redirties those child
                // bindings and re-triggers this one in the same pass).
                // Confirmed via journalctl -b -u sddm during the 2026-09-11
                // 3-screen hardware check: "QML NebulaSurface: Binding loop
                // detected for property visible" fired on every screen.
                visible: sessionSelector.model.length > 0 || virtualKeyboard.available
                    || networkModel.ethernetPresent || networkModel.wifiPresent

                // See contextPanel above for why this is plain x/y, not
                // anchors.*.
                x: stage.width - width
                y: centerCard.y + (centerCard.height - height) / 2

                Flow {
                    id: controlsFlow
                    flow: Flow.TopToBottom
                    spacing: root.theme.spacing.spacingMd
                    // Unconstrained width == content-hugging: a plain
                    // vertical stack, sized to whatever it actually
                    // contains rather than a fixed/forced width.
                    NetworkStatus {
                        id: networkStatus
                        theme: root.theme
                        model: networkModel
                        visible: networkModel.ethernetPresent || networkModel.wifiPresent
                        width: Math.round(180 * root.uiScale)
                    }

                    // Group-hierarchy spacers (wide/vertical stack only —
                    // visual refinement pass): the Flow's own `spacing`
                    // already separates every child equally, which read
                    // as one undifferentiated list; these add extra air
                    // only *between* the three logical groups (Network /
                    // Session+Keyboard / Power), not within Session+
                    // Keyboard, without touching Core or the breakpoint
                    // geometry itself. Each is only visible when both the
                    // group it follows and the group it precedes are
                    // actually shown, so hiding Network (e.g. no adapter
                    // present) never leaves a lone orphaned gap.
                    Item {
                        visible: networkStatus.visible && sessionSelectorColumn.visible
                        width: 1
                        height: root.theme.spacing.spacingSm
                    }
                    Column {
                        id: sessionSelectorColumn
                        visible: sessionSelector.model.length > 0
                        spacing: root.theme.spacing.spacingXs

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Session"
                            color: root.theme.colors.textSecondary
                            font.family: root.theme.typography.fontFamilySecondary
                            font.pixelSize: root.theme.typography.fontSizeBody * 0.8
                        }

                        // SessionDropdown (theme-local, see that file for
                        // the full rationale) replaces Core's pill-row
                        // NebulaSessionSelector here only — user asked for
                        // a dropdown for the session choice specifically;
                        // nord/glass-dark/glass-light keep the Core pills.
                        SessionDropdown {
                            id: sessionSelector
                            theme: root.theme
                            sessionService: sessionService
                            overlayParent: stage
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
            // small fixed margin (`_powerBottomMargin`, ~14px at uiScale
            // 1) deliberately NOT derived from spacingXl or any other
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
            // Round 7: switched from NebulaPowerButtons to the
            // theme-local PowerActions (themes/dashboard/components/) —
            // plain-text actions per the user's mockup, which
            // NebulaButton can't currently express even via its "ghost"
            // variant (always keeps a border at rest). See
            // PowerActions.qml for the full rationale; it still goes
            // through the same NebulaPowerService `powerRow` always
            // used. `firstFocusItem`/`lastFocusItem` (not `powerRow`
            // itself, which holds no focus) are what keyboardToggle/
            // sessionSelector/userList now target — see those bindings
            // above.
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
