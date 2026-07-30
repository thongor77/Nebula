import QtQuick
import "../theme"

// Generic interactive button — reusable building block for any action
// (composed by NebulaPowerButtons later). See docs/Core-API.md for the
// full contract.
Rectangle {
    id: root

    required property NebulaThemeProvider theme

    property string label: ""
    property url icon: ""
    // "primary" | "secondary" | "ghost" — see docs/Core-API.md.
    property string variant: "primary"

    signal clicked()

    implicitWidth: content.implicitWidth + theme.spacing.spacingLg * 2
    implicitHeight: content.implicitHeight + theme.spacing.spacingMd * 2
    radius: theme.radius.radiusMedium
    opacity: enabled ? 1.0 : 0.5

    activeFocusOnTab: true

    readonly property color baseColor: {
        switch (variant) {
        case "secondary": return theme.colors.secondaryColor
        case "ghost": return "transparent"
        default: return theme.colors.primaryColor
        }
    }

    color: mouseArea.pressed ? Qt.darker(baseColor, 1.3) : baseColor
    border.width: activeFocus ? 2 : (variant === "ghost" ? 1 : 0)
    border.color: activeFocus ? theme.colors.accentColor : theme.colors.textSecondary

    // Simple, one-shot interaction feedback — not a permanent/looping
    // animation, so it stays compliant with the "no animation on an
    // invisible/idle component" rule (docs/Architecture.md §5.4).
    scale: mouseArea.pressed ? 0.97 : 1.0

    Behavior on scale {
        NumberAnimation { duration: root.theme.animation.durationFast; easing.type: Easing.OutQuad }
    }
    Behavior on color {
        ColorAnimation { duration: root.theme.animation.durationFast }
    }

    // TODO(Phase 3+): route this Behavior through NebulaAnimationManager
    // once it exists, instead of using the duration token directly — see
    // docs/Core-Implementation-Status.md.

    Row {
        id: content
        anchors.centerIn: parent
        spacing: theme.spacing.spacingSm

        Image {
            source: root.icon
            visible: root.icon.toString().length > 0
            width: theme.typography.fontSizeBody
            height: width
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label
            color: theme.colors.textPrimary
            font.family: theme.typography.fontFamilyPrimary
            font.pixelSize: theme.typography.fontSizeBody
            font.weight: theme.typography.fontWeightNormal
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }

    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
}
