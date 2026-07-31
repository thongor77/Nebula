import QtQuick
import "../theme"

// Generic panel behind any card-like content (login card, user card,
// dialog, future session menu, ...). Handles only padding, radius,
// border and opacity, plus an optional flat shadow approximation — no
// blur, no ShaderEffect (see docs/Rendering-Guidelines.md). Never knows
// about a theme's identity — themes only ever change Design System
// tokens (see docs/Core-API.md).
//
// Contract: sizes itself to hug its content exactly (like
// NebulaLoginLayout's zones, see docs/Development-Journal.md, Phase 1.3)
// — content placed here must not use `anchors.centerIn: parent`, only
// `anchors.horizontalCenter`/`verticalCenter` if needed, to avoid the
// same binding loop documented in DT-0011.
Item {
    id: root

    required property NebulaThemeProvider theme

    default property alias content: contentContainer.data

    property real padding: theme.spacing.spacingMd
    property real radius: theme.radius.radiusLarge
    property real borderWidth: theme.surface.surfaceBorderWidth
    property color borderColor: theme.colors.textSecondary
    property color surfaceColor: theme.colors.surfaceColor

    // Deliberately flat shadow approximation — a plain offset Rectangle,
    // not a blurred drop shadow (that would need ShaderEffect/blur,
    // explicitly avoided in Core). Off by default; a theme opts in.
    property bool shadowEnabled: false
    property color shadowColor: "#000000"
    property real shadowOffset: 2
    property real shadowOpacity: 0.25

    implicitWidth: contentContainer.childrenRect.width + padding * 2
    implicitHeight: contentContainer.childrenRect.height + padding * 2

    Rectangle {
        visible: root.shadowEnabled
        anchors.fill: panel
        anchors.topMargin: root.shadowOffset
        anchors.leftMargin: root.shadowOffset
        radius: root.radius
        color: root.shadowColor
        opacity: root.shadowOpacity
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: root.radius
        color: root.surfaceColor
        opacity: root.theme.surface.surfaceOpacity
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
