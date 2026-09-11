import QtQuick
import "../../../core/theme"
import "../../../core/services"

// Theme-local (Dashboard only) dropdown presentation for session
// selection. Core's NebulaSessionSelector.qml keeps its pill-row
// presentation unchanged for nord/glass-dark/glass-light — Core is
// frozen (docs/API-Stability-Review.md) and a dropdown hasn't been
// demonstrated as a cross-theme need yet. Same bar and rationale as
// PowerActions/PowerTextAction earlier this session: theme-local now,
// Core candidate later if a second independent theme asks for the same
// dropdown pattern (at which point a presentation-neutral
// session-selection primitive could be reconsidered).
//
// Reuses NebulaSessionService directly — the exact contract
// NebulaSessionSelector itself uses — so no session/platform logic is
// duplicated here, only presentation (collapsed value, expandable list,
// keyboard navigation, focus state).
Item {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaSessionService sessionService

    // Item the expanded list reparents into while open, so it paints
    // above later siblings (e.g. the "Show Keyboard" button below this
    // in Main.qml) and isn't clipped by the immediate Flow/Column
    // ancestor, which only ever sizes to this component's collapsed
    // state. Main.qml passes its full-screen `stage` item.
    required property Item overlayParent

    readonly property var model: root.sessionService.sessions
    readonly property int currentIndex: root.sessionService.currentIndex
    readonly property var currentSession: (root.currentIndex >= 0 && root.currentIndex < root.model.length)
        ? root.model[root.currentIndex] : null

    property bool expanded: false

    signal sessionSelected(var session)

    implicitWidth: collapsed.implicitWidth
    implicitHeight: collapsed.implicitHeight
    activeFocusOnTab: true

    function selectIndex(index) {
        if (index < 0 || index >= root.model.length) {
            return
        }
        root.sessionService.selectSession(index)
        root.sessionSelected(root.model[index])
        root.expanded = false
    }

    onActiveFocusChanged: {
        if (!root.activeFocus) {
            root.expanded = false
        }
    }

    // Up/Down rather than the pill version's Left/Right — the
    // idiomatic interaction for an expandable list. Mirrors that
    // version's "no separate highlight step" simplicity: an arrow key
    // switches the actual session immediately, it doesn't just move a
    // highlight.
    Keys.onReturnPressed: root.expanded = !root.expanded
    Keys.onEnterPressed: root.expanded = !root.expanded
    Keys.onSpacePressed: root.expanded = !root.expanded
    Keys.onEscapePressed: root.expanded = false
    Keys.onDownPressed: {
        if (!root.expanded) {
            root.expanded = true
        } else {
            root.selectIndex(Math.min(root.currentIndex + 1, root.model.length - 1))
        }
    }
    Keys.onUpPressed: {
        if (root.expanded) {
            root.selectIndex(Math.max(root.currentIndex - 1, 0))
        }
    }

    // Invisible metrics row — sizes the trigger and the list to fit the
    // widest session name, not just whichever one happens to be
    // current, so switching selection never resizes the control.
    Item {
        id: metrics
        visible: false
        height: 0
        width: 0

        Repeater {
            model: root.model
            Text {
                font.family: root.theme.typography.fontFamilyPrimary
                font.pixelSize: root.theme.typography.fontSizeBody
                text: modelData.displayName
            }
        }
    }

    readonly property real _maxLabelWidth: {
        var max = 0
        for (var i = 0; i < metrics.children.length; i++) {
            max = Math.max(max, metrics.children[i].implicitWidth)
        }
        return max
    }

    Rectangle {
        id: collapsed
        anchors.fill: parent
        implicitWidth: root._maxLabelWidth + chevron.implicitWidth
            + root.theme.spacing.spacingSm + root.theme.spacing.spacingMd * 2
        implicitHeight: label.implicitHeight + root.theme.spacing.spacingSm * 2
        radius: root.theme.radius.radiusSmall
        color: "transparent"
        border.width: root.theme.interaction.borderWidthThin
        border.color: root.activeFocus ? root.theme.colors.accentColor : root.theme.colors.textSecondary

        Row {
            anchors.centerIn: parent
            spacing: root.theme.spacing.spacingSm

            Text {
                id: label
                text: root.currentSession ? root.currentSession.displayName : ""
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamilyPrimary
                font.pixelSize: root.theme.typography.fontSizeBody
            }

            Text {
                id: chevron
                text: root.expanded ? "▴" : "▾"
                color: root.theme.colors.textSecondary
                font.pixelSize: root.theme.typography.fontSizeBody
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.forceActiveFocus()
                root.expanded = !root.expanded
            }
        }
    }

    // Keyboard-focus outline — same pattern PowerTextAction uses.
    Rectangle {
        visible: root.activeFocus
        anchors.fill: collapsed
        anchors.margins: -root.theme.spacing.spacingXs
        radius: root.theme.radius.radiusSmall
        color: "transparent"
        border.width: root.theme.interaction.borderWidthFocus
        border.color: root.theme.colors.accentColor
    }

    // Click-outside-to-close catcher — only present while expanded,
    // reparented alongside the list itself so it covers the same
    // full-screen area; kept below the list in z-order so clicks on the
    // options themselves still reach them, not this.
    MouseArea {
        parent: root.overlayParent
        z: 999
        visible: root.expanded
        anchors.fill: parent
        onClicked: root.expanded = false
    }

    Rectangle {
        id: list
        parent: root.overlayParent
        z: 1000
        visible: root.expanded

        readonly property point _origin: root.mapToItem(root.overlayParent, 0, root.height + root.theme.spacing.spacingXs)
        x: _origin.x
        y: _origin.y
        width: root.width
        implicitHeight: listColumn.implicitHeight + root.theme.spacing.spacingSm * 2
        height: implicitHeight

        radius: root.theme.radius.radiusSmall
        color: root.theme.colors.surfaceColor
        border.width: root.theme.interaction.borderWidthThin
        border.color: root.theme.colors.textSecondary

        Column {
            id: listColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.theme.spacing.spacingSm
            spacing: 0

            Repeater {
                model: root.model

                Rectangle {
                    id: optionRow
                    readonly property bool isCurrent: index === root.currentIndex
                    width: listColumn.width
                    implicitHeight: optionLabel.implicitHeight + root.theme.spacing.spacingSm * 2
                    height: implicitHeight
                    radius: root.theme.radius.radiusSmall
                    color: isCurrent ? root.theme.colors.primaryColor
                        : optionMouse.containsMouse ? Qt.darker(root.theme.colors.surfaceColor, 1.3)
                        : "transparent"

                    Text {
                        id: optionLabel
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.spacing.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.displayName
                        color: optionRow.isCurrent ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                        font.family: root.theme.typography.fontFamilyPrimary
                        font.pixelSize: root.theme.typography.fontSizeBody
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectIndex(index)
                    }
                }
            }
        }
    }
}
