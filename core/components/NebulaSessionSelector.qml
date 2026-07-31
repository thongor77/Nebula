import QtQuick
import "../theme"
import "../services"

// Chooses which session to launch — never reads SDDM's `sessionModel`
// directly (see docs/Nebula-Principles.md §4). See docs/Core-API.md and
// docs/Login-Architecture.md for the full contract.
Item {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaSessionService sessionService

    readonly property var model: sessionService.sessions
    readonly property int currentIndex: sessionService.currentIndex
    readonly property var currentSession: (currentIndex >= 0 && currentIndex < model.length)
        ? model[currentIndex] : null

    signal sessionSelected(var session)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    activeFocusOnTab: true

    function selectIndex(index) {
        if (index < 0 || index >= root.model.length) {
            return
        }
        root.sessionService.selectSession(index)
        root.sessionSelected(root.model[index])
    }

    Row {
        id: row
        spacing: root.theme.spacing.spacingSm

        Repeater {
            model: root.model

            Rectangle {
                id: pill
                readonly property bool isCurrent: index === root.currentIndex

                implicitWidth: label.implicitWidth + root.theme.spacing.spacingMd * 2
                implicitHeight: label.implicitHeight + root.theme.spacing.spacingSm * 2
                radius: root.theme.radius.radiusPill
                color: isCurrent ? root.theme.colors.primaryColor : "transparent"
                border.width: isCurrent ? 0 : root.theme.interaction.borderWidthThin
                border.color: root.theme.colors.textSecondary

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData.displayName
                    color: pill.isCurrent ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamilyPrimary
                    font.pixelSize: root.theme.typography.fontSizeBody
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectIndex(index)
                }
            }
        }
    }

    Keys.onLeftPressed: root.selectIndex(root.currentIndex - 1)
    Keys.onRightPressed: root.selectIndex(root.currentIndex + 1)
}
