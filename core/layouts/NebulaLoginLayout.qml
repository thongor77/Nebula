import QtQuick
import "../theme"

// The common skeleton every theme's login screen is built on top of.
// Pure geometry — layout, margins, spacing, responsive sizing. No SDDM
// logic, no color, no asset (see docs/Core-API.md). Themes plug their
// own components into the four zones below; this component never knows
// what those components are (Cyberpunk, Nord, Glass, ... — see
// docs/Core-API.md §1).
//
// Multi-screen is handled upstream, not here: SDDM instantiates one
// QQuickView (and therefore one NebulaLoginLayout) per physical screen
// (see docs/Prototype-Results.md §3.3), each with its own size. This
// component only has to stay correct for whatever single size it is
// given — it never assumes a fixed resolution or aspect ratio.
Item {
    id: root

    required property NebulaThemeProvider theme

    anchors.fill: parent

    // Shared responsive width cap for the Main Content and Status zones
    // (90% of the available width, never wider than 640). This is a
    // layout contract of the Core itself, not a themeable design value —
    // no theme should be able to make a login card absurdly wide on a
    // 4K screen — so it deliberately stays a local, non-token constant
    // (Phase 1.6 audit, docs/Development-Journal.md). Kept as one shared
    // property instead of duplicating the expression in both zones.
    readonly property real _contentWidth: Math.min(root.width * 0.9, 640)

    // Additive, neutral vertical offset — this layout still knows
    // nothing about a virtual keyboard or any other specific widget; a
    // theme binds it (e.g. to NebulaVirtualKeyboard.reservedHeight, see
    // docs/Core-API.md) to keep the main content and footer visible
    // above whatever is covering the bottom of the screen. Clamped
    // internally so a runaway binding can't push content off-screen.
    property real bottomInset: 0
    readonly property real _clampedBottomInset: Math.min(root.bottomInset, root.height / 2)

    // Wallpaper Area — full-bleed background slot (e.g. a future
    // NebulaBackground). Declared first so it paints behind every other
    // zone.
    property alias wallpaperContent: wallpaperArea.data
    Item {
        id: wallpaperArea
        anchors.fill: parent
    }

    // Main Content Area — the primary interactive column (avatar, clock,
    // date, password field, ...). Width is capped so it doesn't stretch
    // absurdly wide on ultrawide/4K screens, but stays percentage-based
    // so it still fits narrower windows. This is the default zone: an
    // anonymous child of NebulaLoginLayout lands here.
    //
    // Contract: this zone's height hugs its content exactly
    // (childrenRect-based) — content placed here must center itself
    // *horizontally only* (`anchors.horizontalCenter: parent.horizontalCenter`),
    // never with `anchors.centerIn: parent`, which would bind its own
    // position to a height that is itself derived from that same
    // content — a binding loop found and fixed during Phase 1.3 (see
    // docs/Development-Journal.md).
    default property alias mainContent: mainArea.data
    Item {
        id: mainArea
        anchors.horizontalCenter: parent.horizontalCenter
        width: root._contentWidth
        height: childrenRect.height

        // Centered within the space actually left between statusArea and
        // footerArea, not the whole screen — centering in the whole
        // screen with only a partial (half-bottomInset) offset let a tall
        // footer (e.g. a theme with 3 stacked footer rows) overlap this
        // content on screens without much spare vertical room: footerArea
        // moves up by the *full* bottomInset while this only moved up by
        // half of it, so the asymmetry ran out of slack on smaller
        // screens even though it looked fine on a spacious one (real bug,
        // found testing VK-001's keyboard toggle on a 3-monitor rig).
        readonly property real _availableTop: statusArea.height
        readonly property real _availableBottom: footerArea.y
        y: Math.max(_availableTop, (_availableTop + _availableBottom - height) / 2)

        Behavior on y {
            NumberAnimation { duration: root.theme.animation.durationNormal }
        }
    }

    // Status Area — transient system messages (e.g. a future
    // NebulaNotification). Anchored to the top so it never overlaps the
    // centered main content. Same contract as Main Content Area above:
    // content must center horizontally only, never with `centerIn`.
    property alias statusContent: statusArea.data
    Item {
        id: statusArea
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.theme.spacing.spacingLg
        width: root._contentWidth
        height: childrenRect.height
    }

    // Footer Area — session/keyboard selectors, power actions (e.g. a
    // future NebulaPowerButtons row). Anchored to the bottom edge;
    // whatever is placed here arranges itself internally.
    property alias footerContent: footerArea.data
    Item {
        id: footerArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: root.theme.spacing.spacingLg + root._clampedBottomInset
        anchors.leftMargin: root.theme.spacing.spacingLg
        anchors.rightMargin: root.theme.spacing.spacingLg
        height: childrenRect.height

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: root.theme.animation.durationNormal }
        }
    }
}
