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
        anchors.centerIn: parent
        width: root._contentWidth
        height: childrenRect.height
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
        anchors.bottomMargin: root.theme.spacing.spacingLg
        anchors.leftMargin: root.theme.spacing.spacingLg
        anchors.rightMargin: root.theme.spacing.spacingLg
        height: childrenRect.height
    }
}
