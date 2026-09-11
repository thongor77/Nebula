import QtQuick
import "../../../core/theme"

// Theme-local (Dashboard only) plain-text system action — see
// PowerActions.qml for the full architectural rationale. Not a Core
// component: NebulaButton always draws a filled/bordered Rectangle (even
// variant:"ghost" keeps a border at rest), so a no-chrome-at-rest text
// action isn't expressible through it today.
Item {
    id: root

    required property NebulaThemeProvider theme
    property string label: ""
    property string confirmLabel: "Confirm?"
    property bool confirmBeforeAction: false
    property bool armed: false

    signal triggered()

    readonly property int _confirmTimeout: 3000

    implicitWidth: label_.implicitWidth
    implicitHeight: label_.implicitHeight
    activeFocusOnTab: true
    opacity: root.enabled ? 1.0 : root.theme.interaction.opacityDisabled

    function _activate() {
        if (root.confirmBeforeAction && !root.armed) {
            root.armed = true
            confirmResetTimer.restart()
            return
        }
        root.armed = false
        confirmResetTimer.stop()
        root.triggered()
    }

    Keys.onReturnPressed: root._activate()
    Keys.onEnterPressed: root._activate()
    Keys.onSpacePressed: root._activate()

    Timer {
        id: confirmResetTimer
        interval: root._confirmTimeout
        onTriggered: root.armed = false
    }

    // No background/border at rest — the mockup's explicit ask. Hover
    // and pressed both read as accent-colored + underlined (the mockup
    // doesn't visually distinguish them); keyboard focus additionally
    // gets a bold weight plus the outline box below, since color alone
    // isn't a reliable focus indicator (mouse hover already uses color).
    Text {
        id: label_
        anchors.centerIn: parent
        text: root.armed ? root.confirmLabel : root.label
        font.family: root.theme.typography.fontFamilyPrimary
        font.pixelSize: root.theme.typography.fontSizeBody
        font.weight: root.activeFocus ? root.theme.typography.fontWeightBold : root.theme.typography.fontWeightNormal
        font.underline: mouseArea.containsMouse || mouseArea.pressed || root.armed
        color: (mouseArea.containsMouse || mouseArea.pressed || root.armed)
            ? root.theme.colors.accentColor
            : root.theme.colors.textPrimary
    }

    // Outline box, keyboard focus only — mockup's "Focus (keyboard)"
    // state. Slightly larger than the text itself (negative margin), not
    // a fixed pixel pad, so it scales with uiScale like everything else.
    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -root.theme.spacing.spacingXs
        radius: root.theme.radius.radiusSmall
        color: "transparent"
        border.width: root.theme.interaction.borderWidthFocus
        border.color: root.theme.colors.accentColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus()
            root._activate()
        }
    }
}
